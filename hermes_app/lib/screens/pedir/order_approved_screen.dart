import 'package:flutter/material.dart';
import '../../models/pedido.dart';
import '../../services/hermes_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatadores.dart';
import '../../widgets/app_card.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/hermes_app_bar.dart';
import '../../widgets/pedido_builder.dart';
import '../../widgets/primary_button.dart';
import 'queue_screen.dart';

/// Tela 3 do fluxo: pedido aprovado (itens já reservados no estoque).
class OrderApprovedScreen extends StatefulWidget {
  final String pedidoId;

  const OrderApprovedScreen({super.key, required this.pedidoId});

  @override
  State<OrderApprovedScreen> createState() => _OrderApprovedScreenState();
}

class _OrderApprovedScreenState extends State<OrderApprovedScreen> {
  bool _cancelando = false;

  Future<void> _cancelar(Pedido pedido) async {
    final ok = await confirmar(
      context,
      titulo: 'Cancelar pedido?',
      mensagem: 'Os itens reservados voltam para o estoque.',
      textoConfirmar: 'Cancelar pedido',
      destrutivo: true,
    );
    if (!ok || !mounted) return;
    setState(() => _cancelando = true);
    try {
      await HermesApi.instance.cancelarPedido(pedido.id);
      if (!mounted) return;
      Navigator.of(context).popUntil((rota) => rota.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancelando = false);
      mostrarErro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HermesAppBar(stageBadge: 'Validação'),
      body: SafeArea(
        top: false,
        child: PedidoBuilder(
          pedidoId: widget.pedidoId,
          builder: (context, pedido) {
            final cancelado = pedido.status == StatusPedido.cancelled;
            final cor = cancelado ? AppColors.warning : AppColors.success;
            final fundo = cancelado ? AppColors.warningBackground : AppColors.successBackground;

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 26),
                        decoration: BoxDecoration(
                          color: fundo,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cor.withOpacity(0.4)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
                              child: Icon(
                                cancelado ? Icons.close_rounded : Icons.check_rounded,
                                color: AppColors.background,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              cancelado ? 'Pedido Cancelado' : 'Pedido Aprovado',
                              style: TextStyle(color: cor, fontSize: 19, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cancelado ? 'As unidades voltaram para o estoque' : 'Itens reservados no estoque',
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('CÓDIGO DO PEDIDO', style: AppTextStyles.sectionLabel),
                                    const SizedBox(height: 4),
                                    Text(
                                      pedido.codigo,
                                      style: AppTextStyles.screenTitle.copyWith(fontSize: 20),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentBackground,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.accentDim),
                                  ),
                                  child: Text(
                                    pedido.categoria.nomeCompleto.toUpperCase(),
                                    style: AppTextStyles.badge.copyWith(fontSize: 10.5),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Divider(color: AppColors.divider, height: 1),
                            ),
                            _InfoLinha(
                              rotulo: 'Item Solicitado',
                              valor: pedido.itens.map((l) => l.nome).join(', '),
                            ),
                            const SizedBox(height: 14),
                            _InfoLinha(
                              rotulo: 'Quantidade',
                              valor: quantidadeEmTexto(pedido.totalUnidades),
                              cor: AppColors.accent,
                            ),
                            const SizedBox(height: 14),
                            _InfoLinha(rotulo: 'Destino', valor: pedido.localNome),
                            const SizedBox(height: 14),
                            _InfoLinha(rotulo: 'Solicitante', valor: pedido.solicitanteComSetor),
                            const SizedBox(height: 14),
                            _InfoLinha(rotulo: 'Horário', valor: horaRelativa(pedido.criadoEm)),
                          ],
                        ),
                      ),
                      if (pedido.status.ativo) ...[
                        const SizedBox(height: 14),
                        AppCard(
                          child: Row(
                            children: [
                              Icon(Icons.access_time_rounded, color: AppColors.accent, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('PREVISÃO DE ENTREGA', style: AppTextStyles.sectionLabel),
                                    const SizedBox(height: 4),
                                    Text(
                                      pedido.status == StatusPedido.arrived
                                          ? 'Chegou'
                                          : textoEta(pedido.previsaoEntrega),
                                      style: AppTextStyles.screenTitle.copyWith(fontSize: 18),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: pedido.status.ativo
                      ? PrimaryButton(
                          label: 'Acompanhar Fila',
                          icon: Icons.arrow_forward_rounded,
                          iconOnRight: true,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => QueueScreen(pedidoId: pedido.id)),
                            );
                          },
                        )
                      : PrimaryButton(
                          label: 'Voltar ao início',
                          icon: Icons.home_rounded,
                          onPressed: () => Navigator.of(context).popUntil((rota) => rota.isFirst),
                        ),
                ),
                if (pedido.status == StatusPedido.queued)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _cancelando
                        ? SizedBox(
                            height: 40,
                            child: Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.warning),
                              ),
                            ),
                          )
                        : TextButton(
                            onPressed: () => _cancelar(pedido),
                            child: Text(
                              'Cancelar pedido',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                  )
                else
                  const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoLinha extends StatelessWidget {
  final String rotulo;
  final String valor;
  final Color? cor;

  const _InfoLinha({required this.rotulo, required this.valor, this.cor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(rotulo, style: AppTextStyles.cardSubtitle),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.right,
            style: AppTextStyles.cardTitle.copyWith(color: cor),
          ),
        ),
      ],
    );
  }
}
