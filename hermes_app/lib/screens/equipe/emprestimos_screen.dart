import 'package:flutter/material.dart';
import '../../data/emprestimos_repository.dart';
import '../../models/emprestimo.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatadores.dart';
import '../../utils/icones.dart';
import '../../widgets/app_card.dart';
import '../../widgets/chips_status.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/estados.dart';
import '../../widgets/hermes_app_bar.dart';
import '../../widgets/icone_quadrado.dart';
import 'registrar_devolucao_sheet.dart';

enum _Filtro { aReceber, comUsuarios, todos }

/// Equipe: empréstimos em andamento (o que precisa voltar) e recebimento das devoluções.
class EmprestimosScreen extends StatefulWidget {
  const EmprestimosScreen({super.key});

  @override
  State<EmprestimosScreen> createState() => _EmprestimosScreenState();
}

class _EmprestimosScreenState extends State<EmprestimosScreen> {
  late final Stream<List<Emprestimo>> _abertos;
  _Filtro _filtro = _Filtro.aReceber;

  @override
  void initState() {
    super.initState();
    _abertos = EmprestimosRepository().watchAbertos();
  }

  bool _passa(Emprestimo e) {
    switch (_filtro) {
      case _Filtro.aReceber:
        return e.status == StatusEmprestimo.devolucaoSolicitada;
      case _Filtro.comUsuarios:
        return e.status == StatusEmprestimo.emPosse;
      case _Filtro.todos:
        return true;
    }
  }

  Future<void> _abrir(Emprestimo e) async {
    if (e.status != StatusEmprestimo.devolucaoSolicitada) {
      mostrarAviso(context, 'O recebimento só é liberado depois que o usuário pede o recolhimento.');
      return;
    }
    final r = await mostrarRegistrarDevolucao(context, e);
    if (r == null || !mounted) return;
    mostrarAviso(
      context,
      r.restante == 0 ? 'Devolução concluída.' : 'Devolução registrada. Ainda restam ${r.restante} com o usuário.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HermesAppBar(stageBadge: 'Empréstimos'),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<Emprestimo>>(
          stream: _abertos,
          builder: (context, snap) {
            if (snap.hasError) return EstadoErro(erro: snap.error!);
            if (!snap.hasData) return EstadoCarregando();

            final todos = snap.data!;
            final aReceber = todos.where((e) => e.status == StatusEmprestimo.devolucaoSolicitada).length;
            final comUsuarios = todos.where((e) => e.status == StatusEmprestimo.emPosse).length;
            final lista = todos.where(_passa).toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: _FiltroChip(
                          rotulo: 'A receber',
                          contagem: aReceber,
                          selecionado: _filtro == _Filtro.aReceber,
                          onTap: () => setState(() => _filtro = _Filtro.aReceber),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FiltroChip(
                          rotulo: 'Com usuários',
                          contagem: comUsuarios,
                          selecionado: _filtro == _Filtro.comUsuarios,
                          onTap: () => setState(() => _filtro = _Filtro.comUsuarios),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _FiltroChip(
                          rotulo: 'Todos',
                          contagem: todos.length,
                          selecionado: _filtro == _Filtro.todos,
                          onTap: () => setState(() => _filtro = _Filtro.todos),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: lista.isEmpty
                      ? EstadoVazio(
                          icone: Icons.assignment_turned_in_outlined,
                          titulo: _filtro == _Filtro.aReceber
                              ? 'Nenhuma devolução para receber'
                              : 'Nenhum empréstimo nesta lista',
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          children: [
                            for (final e in lista)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _CartaoEmprestimo(emprestimo: e, onTap: () => _abrir(e)),
                              ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  final String rotulo;
  final int contagem;
  final bool selecionado;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.rotulo,
    required this.contagem,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: selecionado ? AppColors.accentBackground : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selecionado ? AppColors.accent : AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              '$contagem',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: selecionado ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              rotulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selecionado ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoEmprestimo extends StatelessWidget {
  final Emprestimo emprestimo;
  final VoidCallback onTap;

  const _CartaoEmprestimo({required this.emprestimo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final e = emprestimo;
    final pedido = e.status == StatusEmprestimo.devolucaoSolicitada;
    return AppCard(
      onTap: onTap,
      borderColor: pedido ? AppColors.accent : AppColors.border,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconeQuadrado(icone: iconeItem(e.itemNome)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.itemNome, style: AppTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text(
                  '${e.restante} de ${e.quantidade} com ${e.solicitanteComSetor}',
                  style: AppTextStyles.cardSubtitle.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (e.localNome.isNotEmpty) e.localNome,
                    'entregue ${haQuanto(e.entregueEm)}',
                    if (pedido) 'recolhimento pedido ${haQuanto(e.devolucaoSolicitadaEm)}',
                  ].join(' · '),
                  style: AppTextStyles.cardSubtitle,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          chipStatusEmprestimo(e.status),
        ],
      ),
    );
  }
}
