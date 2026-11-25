import 'util.dart';

enum StatusEmprestimo {
  emPosse('emPosse', 'Com o usuário'),
  devolucaoSolicitada('devolucaoSolicitada', 'Recolhimento solicitado'),
  devolvido('devolvido', 'Devolvido');

  const StatusEmprestimo(this.id, this.rotulo);

  final String id;
  final String rotulo;

  bool get aberto => this != StatusEmprestimo.devolvido;

  static StatusEmprestimo deId(String? id) {
    for (final s in StatusEmprestimo.values) {
      if (s.id == id) return s;
    }
    return StatusEmprestimo.emPosse;
  }
}

class Emprestimo {
  final String id;
  final String pedidoId;
  final String pedidoCodigo;
  final String itemId;
  final String itemNome;
  final int quantidade;
  final int quantidadeDevolvida;
  final int quantidadeDanificada;
  final int quantidadePerdida;
  final String solicitanteId;
  final String solicitanteNome;
  final String? solicitanteSetor;
  final String localNome;
  final String localDetalhe;
  final StatusEmprestimo status;
  final DateTime? devolucaoSolicitadaEm;
  final DateTime? entregueEm;
  final DateTime? devolvidoEm;

  const Emprestimo({
    required this.id,
    required this.pedidoId,
    required this.pedidoCodigo,
    required this.itemId,
    required this.itemNome,
    required this.quantidade,
    required this.quantidadeDevolvida,
    required this.quantidadeDanificada,
    required this.quantidadePerdida,
    required this.solicitanteId,
    required this.solicitanteNome,
    required this.solicitanteSetor,
    required this.localNome,
    required this.localDetalhe,
    required this.status,
    required this.devolucaoSolicitadaEm,
    required this.entregueEm,
    required this.devolvidoEm,
  });

  /// Unidades que ainda estão com o usuário.
  int get restante => quantidade - quantidadeDevolvida - quantidadeDanificada - quantidadePerdida;

  String get solicitanteComSetor {
    final setor = solicitanteSetor;
    return setor == null ? solicitanteNome : '$solicitanteNome ($setor)';
  }

  factory Emprestimo.deDoc(String id, Map<String, dynamic> d) {
    return Emprestimo(
      id: id,
      pedidoId: lerString(d['pedidoId']),
      pedidoCodigo: lerString(d['pedidoCodigo']),
      itemId: lerString(d['itemId']),
      itemNome: lerString(d['itemNome'], 'Item'),
      quantidade: lerInt(d['quantidade']),
      quantidadeDevolvida: lerInt(d['quantidadeDevolvida']),
      quantidadeDanificada: lerInt(d['quantidadeDanificada']),
      quantidadePerdida: lerInt(d['quantidadePerdida']),
      solicitanteId: lerString(d['solicitanteId']),
      solicitanteNome: lerString(d['solicitanteNome'], 'Sem nome'),
      solicitanteSetor: lerStringOpc(d['solicitanteSetor']),
      localNome: lerString(d['localNome']),
      localDetalhe: lerString(d['localDetalhe']),
      status: StatusEmprestimo.deId(lerStringOpc(d['status'])),
      devolucaoSolicitadaEm: lerData(d['devolucaoSolicitadaEm']),
      entregueEm: lerData(d['entregueEm']),
      devolvidoEm: lerData(d['devolvidoEm']),
    );
  }
}
