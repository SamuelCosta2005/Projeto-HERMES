import 'package:flutter/material.dart';
import '../../data/pedidos_repository.dart';
import '../../models/pedido.dart';
import '../../services/hermes_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formatadores.dart';
import '../../services/sessao.dart';
import '../../widgets/app_card.dart';
import '../../widgets/botao_secundario.dart';
import '../../widgets/chips_status.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/estados.dart';
import '../../widgets/hermes_app_bar.dart';
import '../../widgets/primary_button.dart';

/// Equipe: fila completa de entregas e avanço do status (a caminho / chegou).
class EntregasScreen extends StatefulWidget {
  const EntregasScreen({super.key});

  @override
  State<EntregasScreen> createState() => _EntregasScreenState();
}

class _EntregasScreenState extends State<EntregasScreen> {
  late final Stream<List<Pedido>> _pedidos;
  final Set<String> _ocupados = <String>{};

  @override
  void initState() {
    super.initState();
    _pedidos = PedidosRepository().watchAtivos();
  }

  Future<void> _avancar(Pedido p) async {
    final novo = p.status == StatusPedido.queued ? 'inTransit' : 'arrived';
    setState(() => _ocupados.add(p.id));
    try {
      await HermesApi.instance.atualizarStatusEntrega(p.id, novo);
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _ocupados.remove(p.id));
    }
  }

  Future<void> _cancelar(Pedido p) async {
    final sim = await confirmar(
      context,
      titulo: 'Cancelar pedido?',
      mensagem: 'O pedido ${p.codigo} sai da fila e os itens reservados voltam ao estoque.',
      textoConfirmar: 'Cancelar pedido',
      destrutivo: true,
    );
    if (!sim || !mounted) return;
    setState(() => _ocupados.add(p.id));
    try {
      await HermesApi.instance.cancelarPedidoEquipe(p.id);
      if (mounted) mostrarAviso(context, 'Pedido ${p.codigo} cancelado.');
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _ocupados.remove(p.id));
    }
  }

  Future<void> _entregar(Pedido p) async {
    final sim = await confirmar(
      context,
      titulo: 'Dar como entregue?',
      mensagem: 'Use quando o solicitante recebeu mas não confirmou no app. '
          'O pedido ${p.codigo} é concluído e a fila anda.',
      textoConfirmar: 'Dar como entregue',
    );
    if (!sim || !mounted) return;
    setState(() => _ocupados.add(p.id));
    try {
      await HermesApi.instance.entregarPedidoEquipe(p.id);
      if (mounted) mostrarAviso(context, 'Pedido ${p.codigo} entregue.');
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    } finally {
      if (mounted) setState(() => _ocupados.remove(p.id));
    }
  }

  Future<void> _zerarFila(int total) async {
    final sim = await confirmar(
      context,
      titulo: 'Zerar a fila?',
      mensagem: 'Os $total pedido(s) ativo(s) serão cancelados e os itens reservados '
          'voltam ao estoque. Isso não pode ser desfeito.',
      textoConfirmar: 'Zerar fila',
      destrutivo: true,
    );
    if (!sim || !mounted) return;
    try {
      final n = await HermesApi.instance.zerarFila();
      if (mounted) mostrarAviso(context, '$n pedido(s) cancelado(s).');
    } catch (e) {
      if (mounted) mostrarErro(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = Sessao.atual?.papel.ehAdmin ?? false;
    return Scaffold(
      appBar: HermesAppBar(stageBadge: 'Entregas'),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<Pedido>>(
          stream: _pedidos,
          builder: (context, snap) {
            if (snap.hasError) return EstadoErro(erro: snap.error!);
            if (!snap.hasData) return EstadoCarregando();
            final pedidos = snap.data!;
            if (pedidos.isEmpty) {
              return EstadoVazio(
                icone: Icons.local_shipping_outlined,
                titulo: 'Nenhuma entrega pendente',
                subtitulo: 'Os pedidos novos aparecem aqui na ordem da fila.',
              );
            }
            // O robô atende um por vez: só o 1º "na fila" pode sair, e só se
            // ninguém estiver a caminho ou esperando confirmação.
            final robOcupado = pedidos.any(
              (p) => p.status == StatusPedido.inTransit || p.status == StatusPedido.arrived,
            );
            final naFila = pedidos.where((p) => p.status == StatusPedido.queued).toList();
            final idDaVez = naFila.isEmpty ? null : naFila.first.id;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Fila de entregas', style: AppTextStyles.screenTitle)),
                    if (admin)
                      PopupMenuButton<String>(
                        tooltip: 'Mais opções',
                        color: AppColors.surface,
                        icon: Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
                        onSelected: (v) {
                          if (v == 'zerar') _zerarFila(pedidos.length);
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem<String>(
                            value: 'zerar',
                            child: Row(
                              children: [
                                Icon(Icons.delete_sweep_outlined, color: AppColors.warning, size: 18),
                                const SizedBox(width: 10),
                                Text('Zerar fila', style: AppTextStyles.body),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${pedidos.length} pedido(s) ativo(s), do mais antigo para o mais novo.',
                  style: AppTextStyles.screenSubtitle,
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < pedidos.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CartaoEntrega(
                      posicao: i + 1,
                      pedido: pedidos[i],
                      ocupado: _ocupados.contains(pedidos[i].id),
                      suaVez: pedidos[i].id == idDaVez && !robOcupado,
                      onAvancar: () => _avancar(pedidos[i]),
                      onCancelar: () => _cancelar(pedidos[i]),
                      onEntregar: () => _entregar(pedidos[i]),
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

class _CartaoEntrega extends StatelessWidget {
  final int posicao;
  final Pedido pedido;
  final bool ocupado;
  final bool suaVez;
  final VoidCallback onAvancar;
  final VoidCallback onCancelar;
  final VoidCallback onEntregar;

  const _CartaoEntrega({
    required this.posicao,
    required this.pedido,
    required this.ocupado,
    required this.suaVez,
    required this.onAvancar,
    required this.onCancelar,
    required this.onEntregar,
  });

  @override
  Widget build(BuildContext context) {
    final p = pedido;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceAlt,
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '$posicao',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(p.codigo, style: AppTextStyles.cardTitle)),
              chipStatusPedido(p.status),
            ],
          ),
          const SizedBox(height: 12),
          _Linha(icone: Icons.person_outline_rounded, texto: p.solicitanteComSetor),
          const SizedBox(height: 6),
          _Linha(
            icone: Icons.place_outlined,
            texto: p.localDetalhe.isEmpty ? p.localNome : '${p.localNome} · ${p.localDetalhe}',
          ),
          const SizedBox(height: 6),
          _Linha(icone: Icons.inventory_2_outlined, texto: p.resumoItens),
          const SizedBox(height: 6),
          _Linha(icone: Icons.schedule_rounded, texto: 'Pedido ${horaRelativa(p.criadoEm)}'),
          const SizedBox(height: 14),
          if (p.status == StatusPedido.queued) ...[
            if (suaVez)
              PrimaryButton(
                label: 'Iniciar rota',
                icon: Icons.play_arrow_rounded,
                isLoading: ocupado,
                onPressed: onAvancar,
              )
            else
              Text(
                'Aguardando a vez (o robô atende um pedido por vez, na ordem da fila).',
                style: AppTextStyles.cardSubtitle,
              ),
          ] else if (p.status == StatusPedido.inTransit)
            PrimaryButton(
              label: 'Marcar chegada',
              icon: Icons.flag_rounded,
              isLoading: ocupado,
              onPressed: onAvancar,
            )
          else ...[
            Text(
              'Aguardando o solicitante confirmar o recebimento.',
              style: AppTextStyles.cardSubtitle.copyWith(color: AppColors.success),
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Dar como entregue',
              icon: Icons.check_rounded,
              isLoading: ocupado,
              onPressed: onEntregar,
            ),
          ],
          const SizedBox(height: 10),
          BotaoSecundario(
            rotulo: 'Cancelar pedido',
            icone: Icons.close_rounded,
            destrutivo: true,
            onPressed: ocupado ? null : onCancelar,
          ),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _Linha({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(child: Text(texto, style: AppTextStyles.cardSubtitle.copyWith(color: AppColors.textPrimary))),
      ],
    );
  }
}
