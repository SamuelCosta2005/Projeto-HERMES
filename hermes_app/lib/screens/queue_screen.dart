import 'package:flutter/material.dart';
import '../data/queue_repository.dart';
import '../models/order_details.dart';
import '../models/queue_entry.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/hermes_app_bar.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_label.dart';
import 'tracking_screen.dart';

/// Tela 4 do fluxo: posição do pedido na fila e rota de entregas do robô.
class QueueScreen extends StatefulWidget {
  final OrderDetails order;

  const QueueScreen({super.key, required this.order});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  final QueueRepository _repository = MockQueueRepository();
  QueueStatus? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = await _repository.getQueueStatus(widget.order);
    if (!mounted) return;
    setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;

    return Scaffold(
      appBar: const HermesAppBar(stageBadge: 'Fila'),
      body: SafeArea(
        top: false,
        child: status == null
            ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      children: [
                        AppCard(
                          padding: const EdgeInsets.symmetric(vertical: 22),
                          child: Column(
                            children: [
                              const Text(
                                'SUA POSIÇÃO ATUAL',
                                style: AppTextStyles.sectionLabel,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${status.myPosition}º na Fila',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    color: AppColors.textSecondary,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Tempo de espera: ${status.waitMinutes} min',
                                    style: AppTextStyles.cardSubtitle,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        const SectionLabel('Rota de entregas do robô'),
                        const SizedBox(height: 10),
                        ...status.route.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _QueueTile(entry: entry),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: PrimaryButton(
                      label: 'Ver Mapa em Tempo Real',
                      icon: Icons.location_on_rounded,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TrackingScreen(order: widget.order),
                          ),
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

class _QueueTile extends StatelessWidget {
  final QueueEntry entry;
  const _QueueTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: entry.isMine ? AppColors.accent : AppColors.border,
      backgroundColor: entry.isMine ? AppColors.accentBackground : AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: entry.isMine ? AppColors.accent : AppColors.surfaceAlt,
              border: Border.all(
                color: entry.isMine ? AppColors.accent : AppColors.border,
              ),
            ),
            child: Text(
              '${entry.position}',
              style: TextStyle(
                color: entry.isMine ? AppColors.background : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.isMine ? 'Seu Pedido (${entry.orderCode})' : 'Pedido ${entry.orderCode}',
                  style: AppTextStyles.cardTitle,
                ),
                const SizedBox(height: 2),
                Text('Destino: ${entry.destination}', style: AppTextStyles.cardSubtitle),
              ],
            ),
          ),
          Text(
            entry.statusLabel,
            style: TextStyle(
              color: entry.isMine ? AppColors.accent : AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
