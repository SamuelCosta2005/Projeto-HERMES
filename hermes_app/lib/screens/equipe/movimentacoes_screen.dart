import 'package:flutter/material.dart';
import '../../data/movimentacoes_repository.dart';
import '../../models/movimentacao.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatadores.dart';
import '../../widgets/app_card.dart';
import '../../widgets/estados.dart';
import '../../widgets/hermes_app_bar.dart';
import '../../widgets/icone_quadrado.dart';

/// Admin: livro de movimentações de estoque (geral ou de um item).
class MovimentacoesScreen extends StatefulWidget {
  final String? itemId;
  final String? titulo;

  const MovimentacoesScreen({super.key, this.itemId, this.titulo});

  @override
  State<MovimentacoesScreen> createState() => _MovimentacoesScreenState();
}

class _MovimentacoesScreenState extends State<MovimentacoesScreen> {
  late final Stream<List<Movimentacao>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = MovimentacoesRepository().watchRecentes(itemId: widget.itemId);
  }

  String _efeito(Movimentacao m) {
    String s(int n) => n > 0 ? '+$n' : '$n';
    final partes = <String>[];
    if (m.efeitoEstoqueTotal != 0) partes.add('Total ${s(m.efeitoEstoqueTotal)}');
    if (m.efeitoEmUso != 0) partes.add('Em uso ${s(m.efeitoEmUso)}');
    return partes.isEmpty ? '—' : partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final geral = widget.itemId == null;
    return Scaffold(
      appBar: HermesAppBar(stageBadge: 'Movimentações'),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  geral ? 'Últimas movimentações' : (widget.titulo ?? 'Histórico do item'),
                  style: AppTextStyles.screenTitle.copyWith(fontSize: 20),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Movimentacao>>(
                stream: _stream,
                builder: (context, snap) {
                  if (snap.hasError) return EstadoErro(erro: snap.error!);
                  if (!snap.hasData) return EstadoCarregando();
                  final lista = snap.data!;
                  if (lista.isEmpty) {
                    return EstadoVazio(icone: Icons.history_rounded, titulo: 'Nenhuma movimentação ainda');
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    children: [
                      for (final m in lista)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IconeQuadrado(icone: m.tipo.icone),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        geral ? '${m.tipo.rotulo} · ${m.itemNome}' : m.tipo.rotulo,
                                        style: AppTextStyles.cardTitle,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _efeito(m),
                                        style: AppTextStyles.cardSubtitle.copyWith(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (m.motivo != null) ...[
                                        const SizedBox(height: 2),
                                        Text(m.motivo!, style: AppTextStyles.cardSubtitle),
                                      ],
                                      const SizedBox(height: 2),
                                      Text(
                                        'por ${m.realizadoPorNome} · ${dataHora(m.criadoEm)}',
                                        style: AppTextStyles.cardSubtitle.copyWith(color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
