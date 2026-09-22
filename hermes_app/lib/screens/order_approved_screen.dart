import 'package:flutter/material.dart';
import '../models/order_details.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/hermes_app_bar.dart';
import '../widgets/primary_button.dart';
import 'queue_screen.dart';

/// Tela 3 do fluxo: confirmação de que o pedido foi validado/aprovado.
class OrderApprovedScreen extends StatelessWidget {
  final OrderDetails order;

  const OrderApprovedScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HermesAppBar(stageBadge: 'Validação'),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 26),
                    decoration: BoxDecoration(
                      color: AppColors.successBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.success.withOpacity(0.4)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: AppColors.background,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Pedido Aprovado',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Autenticado via credenciais do terminal',
                          style: AppTextStyles.cardSubtitle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CÓDIGO DO PEDIDO',
                                  style: AppTextStyles.sectionLabel,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  order.code,
                                  style: AppTextStyles.screenTitle.copyWith(fontSize: 20),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentBackground,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.accentDim),
                              ),
                              child: Text(
                                order.category.name == 'T.I.'
                                    ? 'TECNOLOGIA DA INFORMAÇÃO'
                                    : order.category.name.toUpperCase(),
                                style: AppTextStyles.badge.copyWith(fontSize: 10.5),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: AppColors.divider, height: 1),
                        ),
                        _InfoRow(label: 'Item Solicitado', value: order.itemsSummary),
                        const SizedBox(height: 14),
                        _InfoRow(
                          label: 'Quantidade',
                          value: order.formattedQuantity,
                          valueColor: AppColors.accent,
                        ),
                        const SizedBox(height: 14),
                        _InfoRow(
                          label: 'Solicitante',
                          value: '${order.requesterName} (${order.requesterSector})',
                        ),
                        const SizedBox(height: 14),
                        _InfoRow(label: 'Horário', value: order.formattedTime),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppCard(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PREVISÃO DE ENTREGA',
                                style: AppTextStyles.sectionLabel,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '~ ${order.etaMinutes} minutos',
                                style: AppTextStyles.screenTitle.copyWith(fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: PrimaryButton(
                label: 'Acompanhar Fila',
                icon: Icons.arrow_forward_rounded,
                iconOnRight: true,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => QueueScreen(order: order)),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.cardSubtitle),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.cardTitle.copyWith(color: valueColor),
          ),
        ),
      ],
    );
  }
}
