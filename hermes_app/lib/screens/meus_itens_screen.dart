import 'package:flutter/material.dart';
import '../data/emprestimos_repository.dart';
import '../data/pedidos_repository.dart';
import '../models/emprestimo.dart';
import '../models/pedido.dart';
import '../services/auth_service.dart';
import '../services/hermes_api.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatadores.dart';
import '../utils/icones.dart';
import '../widgets/app_card.dart';
import '../widgets/botao_secundario.dart';
import '../widgets/chips_status.dart';
import '../widgets/dialogs.dart';
import '../widgets/estados.dart';
import '../widgets/hermes_app_bar.dart';
import '../widgets/icone_quadrado.dart';
import '../widgets/section_label.dart';
import 'pedir/delivery_complete_screen.dart';
import 'pedir/queue_screen.dart';

/// Pedidos em andamento, empréstimos (com pedido de recolhimento) e histórico.
class MeusItensScreen extends StatefulWidget {
  const MeusItensScreen({super.key});

  @override
  State<MeusItensScreen> createState() => _MeusItensScreenState();
}

class _MeusItensScreenState extends State<MeusItensScreen> {
  late final Stream<List<Pedido>> _pedidos;
  late final Stream<List<Emprestimo>> _emprestimos;
  final Set<String> _ocupados = <String>{};

  @override
  void initState() {
    super.initState();
    final uid = AuthService.uid;
    _pedidos = PedidosRepository().watchMeus(uid);
    _emprestimos = EmprestimosRepository().watchMeus(uid);
  }

  Future<void> _pedirRecolhimento(Emprestimo e) async {
    setState(() => _ocupados.add(e.id));
    try {
      await HermesApi.instance.solicitarDevolucao(e.id);
      if (!mounted) return;
      mostrarAviso(context, 'Recolhimento solicitado. O suporte técnico confirma quando receber o item.');
    } catch (erro) {
      if (!mounted) return;
      mostrarErro(context, erro);
    } finally {
      if (mounted) setState(() => _ocupados.remove(e.id));
    }
  }

  void _abrirPedido(Pedido p) {
    if (!p.status.ativo) return;
    final Widget destino = p.status == StatusPedido.arrived
        ? DeliveryCompleteScreen(pedidoId: p.id)
        : QueueScreen(pedidoId: p.id);
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => destino));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HermesAppBar(stageBadge: 'Meus itens'),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<Pedido>>(
          stream: _pedidos,
          builder: (context, ps) {
            if (ps.hasError) return EstadoErro(erro: ps.error!);
            if (!ps.hasData) return EstadoCarregando();
            return StreamBuilder<List<Emprestimo>>(
              stream: _emprestimos,
              builder: (context, es) {
                if (es.hasError) return EstadoErro(erro: es.error!);
                if (!es.hasData) return EstadoCarregando();
                return _lista(ps.data!, es.data!);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _lista(List<Pedido> pedidos, List<Emprestimo> emprestimos) {
    final andamento = pedidos.where((p) => p.status.ativo).toList();
    final abertos = emprestimos.where((e) => e.status.aberto).toList();
    final devolvidos = emprestimos.where((e) => !e.status.aberto).take(10).toList();
    final historico = pedidos.where((p) => !p.status.ativo).take(15).toList();

    if (andamento.isEmpty && abertos.isEmpty && devolvidos.isEmpty && historico.isEmpty) {
      return EstadoVazio(
        icone: Icons.inbox_rounded,
        titulo: 'Nada por aqui ainda',
        subtitulo: 'Seus pedidos e empréstimos aparecem aqui.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        if (andamento.isNotEmpty) ...[
          SectionLabel('Em andamento'),
          const SizedBox(height: 10),
          for (final p in andamento)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CartaoPedido(pedido: p, onTap: () => _abrirPedido(p)),
            ),
          const SizedBox(height: 12),
        ],
        if (abertos.isNotEmpty) ...[
          SectionLabel('Empréstimos'),
          const SizedBox(height: 10),
          for (final e in abertos)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CartaoEmprestimo(
                emprestimo: e,
                ocupado: _ocupados.contains(e.id),
                onPedirRecolhimento: () => _pedirRecolhimento(e),
              ),
            ),
          const SizedBox(height: 12),
        ],
        if (devolvidos.isNotEmpty) ...[
          SectionLabel('Devolvidos recentemente'),
          const SizedBox(height: 10),
          for (final e in devolvidos)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CartaoEmprestimo(emprestimo: e, ocupado: false, onPedirRecolhimento: null),
            ),
          const SizedBox(height: 12),
        ],
        if (historico.isNotEmpty) ...[
          SectionLabel('Histórico de pedidos'),
          const SizedBox(height: 10),
          for (final p in historico)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CartaoPedido(pedido: p, onTap: null),
            ),
        ],
      ],
    );
  }
}

class _CartaoPedido extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback? onTap;

  const _CartaoPedido({required this.pedido, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          IconeQuadrado(icone: Icons.local_shipping_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pedido.codigo, style: AppTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text(pedido.resumoItens, style: AppTextStyles.cardSubtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  'Para ${pedido.localNome} · ${horaRelativa(pedido.criadoEm)}',
                  style: AppTextStyles.cardSubtitle.copyWith(color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          chipStatusPedido(pedido.status),
        ],
      ),
    );
  }
}

class _CartaoEmprestimo extends StatelessWidget {
  final Emprestimo emprestimo;
  final bool ocupado;
  final VoidCallback? onPedirRecolhimento;

  const _CartaoEmprestimo({
    required this.emprestimo,
    required this.ocupado,
    required this.onPedirRecolhimento,
  });

  @override
  Widget build(BuildContext context) {
    final e = emprestimo;
    final aberto = e.status.aberto;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconeQuadrado(icone: iconeItem(e.itemNome)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.itemNome, style: AppTextStyles.cardTitle),
                    const SizedBox(height: 2),
                    Text(
                      aberto
                          ? '${e.restante} de ${e.quantidade} com você · entregue ${haQuanto(e.entregueEm)}'
                          : '${e.quantidade} un · devolvido ${dataHora(e.devolvidoEm)}',
                      style: AppTextStyles.cardSubtitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              chipStatusEmprestimo(e.status),
            ],
          ),
          if (e.status == StatusEmprestimo.emPosse && onPedirRecolhimento != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: BotaoSecundario(
                rotulo: 'Pedir recolhimento',
                icone: Icons.assignment_return_rounded,
                carregando: ocupado,
                onPressed: onPedirRecolhimento,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
