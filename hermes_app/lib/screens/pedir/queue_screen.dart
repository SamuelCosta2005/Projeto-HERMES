import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/pedidos_repository.dart';
import '../../models/fila_info.dart';
import '../../models/pedido.dart';
import '../../services/hermes_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_card.dart';
import '../../widgets/estados.dart';
import '../../widgets/hermes_app_bar.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_label.dart';
import 'tracking_screen.dart';

/// Tela 4 do fluxo: posição na fila.
///
/// PRIVACIDADE: o servidor só devolve posição e status de cada etapa. Nenhum
/// código, destino ou item de outros pedidos chega ao app (nem poderia: as
/// regras do banco só deixam cada usuário ler os próprios pedidos).
class QueueScreen extends StatefulWidget {
  final String pedidoId;

  const QueueScreen({super.key, required this.pedidoId});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  final _repo = PedidosRepository();
  FilaInfo? _fila;
  Object? _erro;
  Timer? _timer;
  StreamSubscription<Pedido?>? _sub;
  StatusPedido? _ultimoStatus;

  @override
  void initState() {
    super.initState();
    _carregar();
    // Mudanças em pedidos de OUTRAS pessoas não alteram o meu documento, então
    // a posição é reconsultada de tempos em tempos.
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _carregar());
    _sub = _repo.watchPedido(widget.pedidoId).listen((pedido) {
      if (pedido == null) return;
      if (_ultimoStatus != null && _ultimoStatus != pedido.status) _carregar();
      _ultimoStatus = pedido.status;
    }, onError: (Object _) {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final fila = await HermesApi.instance.consultarFila(widget.pedidoId);
      if (!mounted) return;
      setState(() {
        _fila = fila;
        _erro = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fila = _fila;
    return Scaffold(
      appBar: HermesAppBar(stageBadge: 'Fila'),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(child: _corpo(fila)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: (fila != null && !fila.naFila)
                  ? PrimaryButton(
                      label: 'Voltar ao início',
                      icon: Icons.home_rounded,
                      onPressed: () => Navigator.of(context).popUntil((rota) => rota.isFirst),
                    )
                  : PrimaryButton(
                      label: 'Ver Mapa em Tempo Real',
                      icon: Icons.location_on_rounded,
                      onPressed: fila == null
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => TrackingScreen(pedidoId: widget.pedidoId),
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

  Widget _corpo(FilaInfo? fila) {
    if (fila == null) {
      if (_erro != null) return EstadoErro(erro: _erro!, onTentarNovamente: _carregar);
      return EstadoCarregando();
    }
    if (!fila.naFila) {
      final entregue = fila.status == StatusPedido.delivered;
      final cancelado = fila.status == StatusPedido.cancelled;
      return EstadoVazio(
        icone: entregue ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
        titulo: entregue
            ? 'Pedido entregue'
            : cancelado
                ? 'Pedido cancelado'
                : 'Este pedido não está mais na fila',
      );
    }

    final esperaTexto = fila.pedidosAFrente == 0
        ? 'Você é o próximo'
        : 'Tempo de espera: ~${fila.esperaEstimadaMin} min';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      children: [
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 22),
          child: Column(
            children: [
              Text('SUA POSIÇÃO ATUAL', style: AppTextStyles.sectionLabel),
              const SizedBox(height: 8),
              Text(
                '${fila.posicao}º na Fila',
                style: TextStyle(color: AppColors.accent, fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time_rounded, color: AppColors.textSecondary, size: 14),
                  const SizedBox(width: 6),
                  Text(esperaTexto, style: AppTextStyles.cardSubtitle),
                ],
              ),
              if (fila.pedidosAFrente > 0) ...[
                const SizedBox(height: 4),
                Text(
                  fila.pedidosAFrente == 1 ? '1 pedido à sua frente' : '${fila.pedidosAFrente} pedidos à sua frente',
                  style: AppTextStyles.cardSubtitle,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        SectionLabel('Rota de entregas do robô'),
        const SizedBox(height: 10),
        for (final etapa in fila.etapas)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _EtapaTile(etapa: etapa),
          ),
      ],
    );
  }
}

class _EtapaTile extends StatelessWidget {
  final EtapaFila etapa;

  const _EtapaTile({required this.etapa});

  @override
  Widget build(BuildContext context) {
    final meu = etapa.ehMeu;
    return AppCard(
      borderColor: meu ? AppColors.accent : AppColors.border,
      backgroundColor: meu ? AppColors.accentBackground : AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: meu ? AppColors.accent : AppColors.surfaceAlt,
              border: Border.all(color: meu ? AppColors.accent : AppColors.border),
            ),
            child: Text(
              '${etapa.ordem}',
              style: TextStyle(
                color: meu ? AppColors.background : AppColors.textSecondary,
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
                Text(meu ? 'Seu pedido' : 'Pedido à frente', style: AppTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text(meu ? 'Entrega para você' : 'Outro solicitante', style: AppTextStyles.cardSubtitle),
              ],
            ),
          ),
          Text(
            etapa.status.rotulo,
            style: TextStyle(
              color: meu ? AppColors.accent : AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
