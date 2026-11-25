import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/pedidos_repository.dart';
import '../../models/pedido.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatadores.dart';
import '../../widgets/app_card.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/hermes_app_bar.dart';
import '../../widgets/mapa_entrega.dart';
import '../../widgets/pedido_builder.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_label.dart';
import 'delivery_complete_screen.dart';

/// Tela 5 do fluxo: acompanhamento da entrega.
///
/// Com o pedido "a caminho", mostra o mapa em tempo real (robô e cliente).
/// Nos outros status mostra um aviso no lugar do mapa. O status, a previsão e
/// as etapas abaixo vêm do banco.
class TrackingScreen extends StatefulWidget {
  final String pedidoId;

  const TrackingScreen({super.key, required this.pedidoId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  StreamSubscription<Pedido?>? _sub;
  StatusPedido? _ultimo;

  @override
  void initState() {
    super.initState();
    _sub = PedidosRepository().watchPedido(widget.pedidoId).listen((pedido) {
      if (pedido == null) return;
      final acabouDeChegar = _ultimo != null && _ultimo != StatusPedido.arrived && pedido.status == StatusPedido.arrived;
      _ultimo = pedido.status;
      if (acabouDeChegar && mounted) {
        mostrarAviso(context, 'O Hermes chegou! Toque em "Verificar Instruções de Recebimento".');
      }
    }, onError: (Object _) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  String _textoStatus(StatusPedido s) {
    switch (s) {
      case StatusPedido.queued:
        return 'Aguardando na fila';
      case StatusPedido.inTransit:
        return 'A caminho do destino';
      case StatusPedido.arrived:
        return 'Chegou ao destino';
      case StatusPedido.delivered:
        return 'Entrega concluída';
      case StatusPedido.cancelled:
        return 'Pedido cancelado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HermesAppBar(stageBadge: 'Localização'),
      body: SafeArea(
        top: false,
        child: PedidoBuilder(
          pedidoId: widget.pedidoId,
          builder: (context, pedido) {
            final chegou = pedido.status == StatusPedido.arrived;
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    children: [
                      SectionLabel('Mapa do campus'),
                      const SizedBox(height: 10),
                      pedido.status == StatusPedido.inTransit
                          ? MapaEntrega()
                          : _MapaPlaceholder(status: pedido.status),
                      const SizedBox(height: 16),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('STATUS DO HERMES', style: AppTextStyles.sectionLabel),
                                      const SizedBox(height: 6),
                                      Text(
                                        _textoStatus(pedido.status),
                                        style: AppTextStyles.cardTitle.copyWith(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('TEMPO ESTIMADO', style: AppTextStyles.sectionLabel),
                                    const SizedBox(height: 6),
                                    Text(
                                      chegou ? 'Chegou' : textoEta(pedido.previsaoEntrega),
                                      style: TextStyle(
                                        color: AppColors.accent,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _Passos(status: pedido.status),
                            const SizedBox(height: 14),
                            Text('Destino: ${pedido.localNome}', style: AppTextStyles.cardSubtitle),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
                  child: PrimaryButton(
                    label: 'Verificar Instruções de Recebimento',
                    icon: Icons.help_outline_rounded,
                    onPressed: chegou
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => DeliveryCompleteScreen(pedidoId: pedido.id),
                              ),
                            );
                          }
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    chegou ? 'O robô está aguardando você.' : 'Disponível quando o robô chegar.',
                    style: AppTextStyles.cardSubtitle.copyWith(fontSize: 11),
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

class _Passos extends StatelessWidget {
  final StatusPedido status;

  const _Passos({required this.status});

  int get _atual {
    switch (status) {
      case StatusPedido.queued:
        return 0;
      case StatusPedido.inTransit:
        return 1;
      case StatusPedido.arrived:
      case StatusPedido.delivered:
        return 2;
      case StatusPedido.cancelled:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    const rotulos = ['Na fila', 'A caminho', 'Chegou'];
    final atual = _atual;
    return Row(
      children: [
        for (var i = 0; i < rotulos.length; i++) ...[
          _Passo(rotulo: rotulos[i], alcancado: i <= atual, atual: i == atual),
          if (i < rotulos.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 18),
                color: i < atual ? AppColors.accent : AppColors.border,
              ),
            ),
        ],
      ],
    );
  }
}

class _Passo extends StatelessWidget {
  final String rotulo;
  final bool alcancado;
  final bool atual;

  const _Passo({required this.rotulo, required this.alcancado, required this.atual});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: alcancado ? AppColors.accent : AppColors.surfaceAlt,
            border: Border.all(color: alcancado ? AppColors.accent : AppColors.border, width: atual ? 2 : 1),
          ),
          child: alcancado ? Icon(Icons.check_rounded, size: 14, color: AppColors.background) : null,
        ),
        const SizedBox(height: 6),
        Text(
          rotulo,
          style: TextStyle(
            fontSize: 11,
            fontWeight: atual ? FontWeight.w800 : FontWeight.w600,
            color: alcancado ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _MapaPlaceholder extends StatelessWidget {
  final StatusPedido status;

  const _MapaPlaceholder({required this.status});

  String get _mensagem {
    switch (status) {
      case StatusPedido.queued:
        return 'O mapa aparece quando o robô sair para a entrega.';
      case StatusPedido.arrived:
        return 'O robô chegou ao destino.';
      case StatusPedido.delivered:
        return 'Entrega concluída.';
      case StatusPedido.cancelled:
        return 'Pedido cancelado.';
      case StatusPedido.inTransit:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map_outlined, color: AppColors.textMuted.withOpacity(0.6), size: 40),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(_mensagem, textAlign: TextAlign.center, style: AppTextStyles.cardSubtitle),
          ),
        ],
      ),
    );
  }
}
