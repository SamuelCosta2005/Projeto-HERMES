import 'package:flutter/material.dart';
import '../models/order_details.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/hermes_app_bar.dart';
import '../widgets/primary_button.dart';
import 'materials_screen.dart';

/// Tela 6 (final) do fluxo: robô chegou, instruções de segurança e
/// confirmação de recebimento dos itens.
class DeliveryCompleteScreen extends StatefulWidget {
  final OrderDetails order;

  const DeliveryCompleteScreen({super.key, required this.order});

  @override
  State<DeliveryCompleteScreen> createState() => _DeliveryCompleteScreenState();
}

class _DeliveryCompleteScreenState extends State<DeliveryCompleteScreen> {
  bool _isConfirming = false;

  Future<void> _onConfirmReceipt() async {
    setState(() => _isConfirming = true);

    // Simula o fechamento da gaveta / liberação do robô para a próxima rota.
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 44),
              const SizedBox(height: 14),
              const Text(
                'Recebimento confirmado!',
                style: AppTextStyles.cardTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'O Hermes fechou a gaveta e seguiu para a próxima rota.',
                style: AppTextStyles.cardSubtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Concluir',
                  icon: Icons.arrow_forward_rounded,
                  iconOnRight: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;
    // Reinicia o fluxo do zero, limpando toda a pilha de navegação e o
    // estado de quantidades selecionadas na tela de materiais.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MaterialsScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      appBar: const HermesAppBar(stageBadge: 'Chegou'),
      body: SafeArea(
        top: false,
        child: Column(
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
                      child: const Icon(
                        Icons.all_inbox_rounded,
                        color: AppColors.accent,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Seu Pedido Chegou!',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'O robô Hermes V2 já está aguardando você na Área de Coleta 4.',
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
                          children: const [
                            Icon(Icons.lock_outline_rounded, color: AppColors.accent, size: 18),
                            SizedBox(width: 8),
                            Text('INSTRUÇÕES DE SEGURANÇA', style: AppTextStyles.sectionLabel),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const _InstructionStep(
                          number: 1,
                          text: 'Aproxime-se do Hermes e confirme sua identidade no painel do robô.',
                        ),
                        const SizedBox(height: 12),
                        const _InstructionStep(
                          number: 2,
                          text: 'O compartimento Nº 3 se abrirá automaticamente.',
                        ),
                        const SizedBox(height: 12),
                        const _InstructionStep(
                          number: 3,
                          text: 'Retire seus itens e clique no botão verde abaixo para fechar e liberar o robô.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.accent,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(order.primaryItem.name, style: AppTextStyles.cardTitle),
                              const SizedBox(height: 2),
                              Text(
                                'Código: ${order.code}',
                                style: AppTextStyles.cardSubtitle,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${order.primaryItem.quantity} un',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: PrimaryButton(
                label: 'Confirmar Recebimento',
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                isLoading: _isConfirming,
                onPressed: _onConfirmReceipt,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Text(
                'Ao confirmar, o Hermes fechará a gaveta e prosseguirá com a rota.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final int number;
  final String text;

  const _InstructionStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: AppColors.background,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body.copyWith(fontSize: 13, height: 1.35),
          ),
        ),
      ],
    );
  }
}
