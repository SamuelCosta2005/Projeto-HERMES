import 'package:flutter/material.dart';
import 'util.dart';

enum TipoMovimentacao {
  entrada('entrada', 'Entrada', Icons.add_box_rounded),
  reserva('reserva', 'Reserva', Icons.bookmark_added_rounded),
  liberacao('liberacao', 'Reserva liberada', Icons.bookmark_remove_rounded),
  consumo('consumo', 'Consumo', Icons.local_shipping_rounded),
  devolucao('devolucao', 'Devolução', Icons.assignment_return_rounded),
  baixa('baixa', 'Baixa', Icons.remove_circle_rounded),
  ajuste('ajuste', 'Ajuste de contagem', Icons.fact_check_rounded);

  const TipoMovimentacao(this.id, this.rotulo, this.icone);

  final String id;
  final String rotulo;
  final IconData icone;

  static TipoMovimentacao deId(String? id) {
    for (final t in TipoMovimentacao.values) {
      if (t.id == id) return t;
    }
    return TipoMovimentacao.ajuste;
  }
}

class Movimentacao {
  final String id;
  final String itemId;
  final String itemNome;
  final TipoMovimentacao tipo;
  final int quantidade;
  final int efeitoEstoqueTotal;
  final int efeitoEmUso;
  final String? motivo;
  final String realizadoPorNome;
  final DateTime? criadoEm;

  const Movimentacao({
    required this.id,
    required this.itemId,
    required this.itemNome,
    required this.tipo,
    required this.quantidade,
    required this.efeitoEstoqueTotal,
    required this.efeitoEmUso,
    required this.motivo,
    required this.realizadoPorNome,
    required this.criadoEm,
  });

  factory Movimentacao.deDoc(String id, Map<String, dynamic> d) {
    return Movimentacao(
      id: id,
      itemId: lerString(d['itemId']),
      itemNome: lerString(d['itemNome'], 'Item'),
      tipo: TipoMovimentacao.deId(lerStringOpc(d['tipo'])),
      quantidade: lerInt(d['quantidade']),
      efeitoEstoqueTotal: lerInt(d['efeitoEstoqueTotal']),
      efeitoEmUso: lerInt(d['efeitoEmUso']),
      motivo: lerStringOpc(d['motivo']),
      realizadoPorNome: lerString(d['realizadoPorNome'], '—'),
      criadoEm: lerData(d['criadoEm']),
    );
  }
}
