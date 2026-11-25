import 'package:flutter/material.dart';
import '../../models/emprestimo.dart';
import '../../services/hermes_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/campo_texto.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/stepper_quantidade.dart';

/// Abre a folha de recebimento. Devolve o resultado se a devolução foi registrada,
/// ou null se o técnico fechou sem confirmar.
Future<ResultadoDevolucao?> mostrarRegistrarDevolucao(BuildContext context, Emprestimo emprestimo) {
  return showModalBottomSheet<ResultadoDevolucao>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _RegistrarDevolucaoSheet(emprestimo: emprestimo),
  );
}

class _RegistrarDevolucaoSheet extends StatefulWidget {
  final Emprestimo emprestimo;

  const _RegistrarDevolucaoSheet({required this.emprestimo});

  @override
  State<_RegistrarDevolucaoSheet> createState() => _RegistrarDevolucaoSheetState();
}

class _RegistrarDevolucaoSheetState extends State<_RegistrarDevolucaoSheet> {
  late int _ok;
  int _danificadas = 0;
  int _perdidas = 0;
  final _obs = TextEditingController();
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    // Por padrão assume que tudo voltou em bom estado; o técnico ajusta se não.
    _ok = widget.emprestimo.restante;
  }

  @override
  void dispose() {
    _obs.dispose();
    super.dispose();
  }

  int get _soma => _ok + _danificadas + _perdidas;
  int get _restante => widget.emprestimo.restante;

  Future<void> _confirmar() async {
    if (_soma < 1 || _enviando) return;
    setState(() => _enviando = true);
    try {
      final r = await HermesApi.instance.registrarDevolucao(
        emprestimoId: widget.emprestimo.id,
        ok: _ok,
        danificadas: _danificadas,
        perdidas: _perdidas,
        observacoes: _obs.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(r);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      mostrarErro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.emprestimo;
    final podeMais = _soma < _restante;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppColors.border),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Receber devolução', style: AppTextStyles.cardTitle.copyWith(fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                '${e.itemNome} · ${e.solicitanteComSetor}',
                style: AppTextStyles.cardSubtitle,
              ),
              const SizedBox(height: 2),
              Text('Faltam devolver: $_restante de ${e.quantidade}', style: AppTextStyles.cardSubtitle),
              const SizedBox(height: 18),
              _LinhaContagem(
                rotulo: 'Em bom estado',
                valor: _ok,
                onMenos: _ok > 0 ? () => setState(() => _ok--) : null,
                onMais: podeMais ? () => setState(() => _ok++) : null,
              ),
              const SizedBox(height: 10),
              _LinhaContagem(
                rotulo: 'Danificadas',
                valor: _danificadas,
                onMenos: _danificadas > 0 ? () => setState(() => _danificadas--) : null,
                onMais: podeMais ? () => setState(() => _danificadas++) : null,
              ),
              const SizedBox(height: 10),
              _LinhaContagem(
                rotulo: 'Perdidas',
                valor: _perdidas,
                onMenos: _perdidas > 0 ? () => setState(() => _perdidas--) : null,
                onMais: podeMais ? () => setState(() => _perdidas++) : null,
              ),
              const SizedBox(height: 6),
              Text(
                _soma < _restante
                    ? 'Se algo ainda não voltou, o empréstimo continua aberto com o restante.'
                    : 'Isso encerra o empréstimo.',
                style: AppTextStyles.cardSubtitle,
              ),
              const SizedBox(height: 14),
              CampoTexto(
                controller: _obs,
                rotulo: 'Observações (opcional)',
                dica: 'Ex.: cabo sem a ponta',
                linhas: 2,
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'Confirmar recebimento',
                icon: Icons.check_circle_rounded,
                isLoading: _enviando,
                onPressed: _soma >= 1 ? _confirmar : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinhaContagem extends StatelessWidget {
  final String rotulo;
  final int valor;
  final VoidCallback? onMenos;
  final VoidCallback? onMais;

  const _LinhaContagem({
    required this.rotulo,
    required this.valor,
    required this.onMenos,
    required this.onMais,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: Text(rotulo, style: AppTextStyles.cardTitle)),
          StepperQuantidade(valor: valor, onMenos: onMenos, onMais: onMais),
        ],
      ),
    );
  }
}
