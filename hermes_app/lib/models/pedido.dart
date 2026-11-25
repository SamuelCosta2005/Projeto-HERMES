import 'categoria.dart';
import 'util.dart';

enum StatusPedido {
  queued('queued', 'Na fila'),
  inTransit('inTransit', 'A caminho'),
  arrived('arrived', 'Chegou'),
  delivered('delivered', 'Entregue'),
  cancelled('cancelled', 'Cancelado');

  const StatusPedido(this.id, this.rotulo);

  final String id;
  final String rotulo;

  /// Ainda faz parte da fila de entregas.
  bool get ativo =>
      this == StatusPedido.queued || this == StatusPedido.inTransit || this == StatusPedido.arrived;

  static StatusPedido deId(String? id) {
    for (final s in StatusPedido.values) {
      if (s.id == id) return s;
    }
    return StatusPedido.queued;
  }
}

class LinhaPedido {
  final String itemId;
  final String nome;
  final int quantidade;
  final bool retornavel;

  const LinhaPedido({
    required this.itemId,
    required this.nome,
    required this.quantidade,
    required this.retornavel,
  });

  factory LinhaPedido.deMapa(Map<String, dynamic> m) {
    return LinhaPedido(
      itemId: lerString(m['itemId']),
      nome: lerString(m['nome'], 'Item'),
      quantidade: lerInt(m['quantidade']),
      retornavel: lerBool(m['retornavel']),
    );
  }
}

class Pedido {
  final String id;
  final String codigo;
  final Categoria categoria;
  final List<LinhaPedido> itens;
  final String localId;
  final String localNome;
  final String localDetalhe;
  final String solicitanteId;
  final String solicitanteNome;
  final String? solicitanteSetor;
  final StatusPedido status;
  final DateTime? previsaoEntrega;
  final DateTime? entregueEm;
  final DateTime? criadoEm;

  const Pedido({
    required this.id,
    required this.codigo,
    required this.categoria,
    required this.itens,
    required this.localId,
    required this.localNome,
    required this.localDetalhe,
    required this.solicitanteId,
    required this.solicitanteNome,
    required this.solicitanteSetor,
    required this.status,
    required this.previsaoEntrega,
    required this.entregueEm,
    required this.criadoEm,
  });

  int get totalUnidades => itens.fold(0, (soma, l) => soma + l.quantidade);
  bool get temRetornavel => itens.any((l) => l.retornavel);

  /// Ex.: "2× Adaptador HDMI, 1× Mouse Óptico USB".
  String get resumoItens => itens.map((l) => '${l.quantidade}× ${l.nome}').join(', ');

  /// Solicitante com setor, quando houver. Ex.: "Roberto Silva (Engenharia)".
  String get solicitanteComSetor {
    final setor = solicitanteSetor;
    return setor == null ? solicitanteNome : '$solicitanteNome ($setor)';
  }

  factory Pedido.deDoc(String id, Map<String, dynamic> d) {
    return Pedido(
      id: id,
      codigo: lerString(d['codigo'], '#HR-????'),
      categoria: Categoria.deId(lerStringOpc(d['categoria'])),
      itens: listaDeMapas(d['itens']).map(LinhaPedido.deMapa).toList(),
      localId: lerString(d['localId']),
      localNome: lerString(d['localNome'], lerString(d['localId'])),
      localDetalhe: lerString(d['localDetalhe']),
      solicitanteId: lerString(d['solicitanteId']),
      solicitanteNome: lerString(d['solicitanteNome'], 'Sem nome'),
      solicitanteSetor: lerStringOpc(d['solicitanteSetor']),
      status: StatusPedido.deId(lerStringOpc(d['status'])),
      previsaoEntrega: lerData(d['previsaoEntrega']),
      entregueEm: lerData(d['entregueEm']),
      criadoEm: lerData(d['criadoEm']),
    );
  }
}
