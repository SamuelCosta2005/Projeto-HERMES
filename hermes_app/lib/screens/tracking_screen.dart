import 'package:flutter/material.dart';
import '../data/tracking_repository.dart';
import '../models/order_details.dart';
import '../models/tracking_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/hermes_app_bar.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_label.dart';
import 'delivery_complete_screen.dart';

/// Tela 5 do fluxo: localização do robô em tempo real.
///
/// Conforme combinado, a área do mapa em si é apenas um placeholder
/// ("imagem não encontrada") — pronta para depois ser substituída por
/// uma integração real de mapa (ex: mapa indoor customizado).
class TrackingScreen extends StatefulWidget {
  final OrderDetails order;

  const TrackingScreen({super.key, required this.order});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final TrackingRepository _repository = MockTrackingRepository();
  TrackingStatus? _status;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final status = await _repository.getTracking(widget.order);
    if (!mounted) return;
    setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;

    return Scaffold(
      appBar: const HermesAppBar(stageBadge: 'Localização'),
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
                        SectionLabel(status.buildingLabel),
                        const SizedBox(height: 10),
                        const _MapPlaceholder(),
                        const SizedBox(height: 16),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'STATUS DO HERMES',
                                          style: AppTextStyles.sectionLabel,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          status.statusText,
                                          style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'TEMPO ESTIMADO',
                                        style: AppTextStyles.sectionLabel,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        status.etaText,
                                        style: const TextStyle(
                                          color: AppColors.accent,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: status.progress,
                                  minHeight: 6,
                                  backgroundColor: AppColors.surfaceAlt,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors.accent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Saída: ${status.originLabel[0]}${status.originLabel.substring(1).toLowerCase()}',
                                    style: AppTextStyles.cardSubtitle,
                                  ),
                                  Text(
                                    status.progressLabel,
                                    style: AppTextStyles.cardSubtitle.copyWith(
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
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
                      label: 'Verificar Instruções de Recebimento',
                      icon: Icons.help_outline_rounded,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DeliveryCompleteScreen(order: widget.order),
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

/// Placeholder da área de mapa — simula uma "imagem não encontrada",
/// como combinado, até que um mapa real seja integrado.
class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            color: AppColors.textMuted.withOpacity(0.6),
            size: 40,
          ),
          const SizedBox(height: 10),
          const Text('Mapa não encontrado', style: AppTextStyles.cardSubtitle),
          const SizedBox(height: 2),
          Text(
            '(placeholder — integrar mapa depois)',
            style: AppTextStyles.cardSubtitle.copyWith(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
