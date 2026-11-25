import 'package:flutter/material.dart';
import '../data/pedidos_repository.dart';
import '../models/pedido.dart';
import 'estados.dart';

/// Acompanha UM pedido em tempo real e entrega o [Pedido] atualizado ao [builder].
class PedidoBuilder extends StatefulWidget {
  final String pedidoId;
  final Widget Function(BuildContext context, Pedido pedido) builder;

  const PedidoBuilder({super.key, required this.pedidoId, required this.builder});

  @override
  State<PedidoBuilder> createState() => _PedidoBuilderState();
}

class _PedidoBuilderState extends State<PedidoBuilder> {
  late final Stream<Pedido?> _stream;

  @override
  void initState() {
    super.initState();
    _stream = PedidosRepository().watchPedido(widget.pedidoId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Pedido?>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) return EstadoErro(erro: snap.error!);
        if (snap.connectionState == ConnectionState.waiting) return EstadoCarregando();
        final pedido = snap.data;
        if (pedido == null) {
          return EstadoVazio(icone: Icons.search_off_rounded, titulo: 'Pedido não encontrado');
        }
        return widget.builder(context, pedido);
      },
    );
  }
}
