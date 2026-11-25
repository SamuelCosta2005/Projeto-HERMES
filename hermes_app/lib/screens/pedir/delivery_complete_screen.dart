import 'package:flutter/material.dart';
import '../../models/pedido.dart';
import '../../services/hermes_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_card.dart';
import '../../widgets/chip_rotulo.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/hermes_app_bar.dart';
import '../../widgets/icone_quadrado.dart';
import '../../widgets/pedido_builder.dart';
import '../../widgets/primary_button.dart';
import '../../utils/icones.dart';

/// Tela 6 (final): o robô chegou; instruções e confirmação de recebimento.
/// Confirmar baixa os consumíveis do estoque e abre empréstimo dos retornáveis.
class DeliveryCompleteScreen extends StatefulWidget {
  final String pedidoId;

  const DeliveryCompleteScreen({super.key, required this.pedidoId});

  @override
  State<DeliveryCompleteScreen> createState() => _DeliveryCompleteScreenState();
}

class _DeliveryCompleteScreenState extends State<DeliveryCompleteScreen> {
  bool _confirmando = false;

  Future<void> _confirmar(Pedido pedido) async {
    setState(() => _confirmando = true);
    try {
      final r = await HermesApi.instance.confirmarRecebimento(pedido.id);
      if (!mounted) return;
      await _dialogoSucesso(r.emprestimosCriados);
      if (!mounted) return;
      Navigator.of(context).popUntil((rota) => rota.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() => _confirmando = false);
      mostrarErro(context, e);
    }
  }

  Future<void> _dialogoSucesso(int emprestimos) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 44),
              const SizedBox(height: 14),
              Text('Recebimento confirmado!', style: AppTextStyles.cardTitle, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(
                emprestimos > 0
                    ? 'Você ficou com itens emprestados. Quando quiser devolver, abra "Meus itens" e peça o recolhimento.'
                    : 'O Hermes fechou a gaveta e seguiu para a próxima rota.',
                style: AppTextStyles.cardSubtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Concluir',
                icon: Icons.arrow_forward_rounded,
                iconOnRight: true,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HermesAppBar(stageBadge: 'Chegou'),
      body: SafeArea(
        top: false,
        child: PedidoBuilder(
          pedidoId: widget.pedidoId,
          builder: (context, pedido) {
            final pode = pedido.status == StatusPedido.arrived;
            final jaEntregue = pedido.status == StatusPedido.delivered;
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    children: [
                      Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.accent, width: 1.6),
                            color: AppColors.accentBackground,
                          ),
                          child: Icon(Icons.all_inbox_rounded, color: AppColors.accent, size: 38),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        jaEntregue ? 'Pedido entregue' : 'Seu Pedido Chegou!',
                        style: TextStyle(color: AppColors.accent, fontSize: 21, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pode
                            ? 'O robô Hermes já está aguardando você em ${pedido.localNome}.'
                            : jaEntregue
                                ? 'O recebimento deste pedido já foi confirmado.'
                                : 'O robô ainda não chegou. Esta tela libera quando ele chegar.',
                        style: AppTextStyles.screenSubtitle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 22),
                      AppCard(
                        borderColor: AppColors.accentDim,
                        backgroundColor: AppColors.accentBackground,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lock_outline_rounded, color: AppColors.accent, size: 18),
                                const SizedBox(width: 8),
                                Text('INSTRUÇÕES DE SEGURANÇA', style: AppTextStyles.sectionLabel),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _Passo(numero: 1, texto: 'Aproxime-se do Hermes e confirme sua identidade no painel do robô.'),
                            const SizedBox(height: 12),
                            _Passo(numero: 2, texto: 'O compartimento do seu pedido se abrirá automaticamente.'),
                            const SizedBox(height: 12),
                            _Passo(
                              numero: 3,
                              texto: 'Retire seus itens e clique no botão verde abaixo para fechar e liberar o robô.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      for (final linha in pedido.itens)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                IconeQuadrado(icone: iconeItem(linha.nome), tamanho: 32),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(linha.nome, style: AppTextStyles.cardTitle),
                                      const SizedBox(height: 2),
                                      Wrap(
                                        spacing: 8,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Text('Código: ${pedido.codigo}', style: AppTextStyles.cardSubtitle),
                                          if (linha.retornavel)
                                            ChipRotulo(
                                              texto: 'Devolver depois',
                                              cor: AppColors.accent,
                                              fundo: AppColors.accentBackground,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${linha.quantidade} un',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: jaEntregue
                      ? PrimaryButton(
                          label: 'Voltar ao início',
                          icon: Icons.home_rounded,
                          onPressed: () => Navigator.of(context).popUntil((rota) => rota.isFirst),
                        )
                      : PrimaryButton(
                          label: 'Confirmar Recebimento',
                          icon: Icons.check_circle_rounded,
                          color: AppColors.success,
                          isLoading: _confirmando,
                          onPressed: pode ? () => _confirmar(pedido) : null,
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    'Ao confirmar, o Hermes fechará a gaveta e prosseguirá com a rota.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                    textAlign: TextAlign.center,
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

class _Passo extends StatelessWidget {
  final int numero;
  final String texto;

  const _Passo({required this.numero, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent),
          child: Text(
            '$numero',
            style: TextStyle(color: AppColors.background, fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(texto, style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.35)),
        ),
      ],
    );
  }
}
