import 'material_category.dart';
import 'material_item.dart';
import 'room.dart';

/// Representa o pedido já confirmado/aprovado, com todos os dados
/// necessários para as telas seguintes do fluxo (fila, rastreio, retirada).
class OrderDetails {
  final String code; // Ex: "#HR-8941"
  final MaterialCategory category;
  final List<MaterialItemModel> items; // itens com quantity > 0
  final Room room;
  final String requesterName;
  final String requesterSector;
  final DateTime requestedAt;
  final int etaMinutes;

  const OrderDetails({
    required this.code,
    required this.category,
    required this.items,
    required this.room,
    required this.requesterName,
    required this.requesterSector,
    required this.requestedAt,
    required this.etaMinutes,
  });

  /// Quantidade total de peças pedidas (soma de todos os itens).
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  /// Texto amigável com o(s) nome(s) do(s) item(ns), usado na tela de
  /// aprovação. Se houver mais de um item, junta os nomes com vírgula.
  String get itemsSummary => items.map((e) => e.name).join(', ');

  /// Primeiro item do pedido — usado como referência principal em telas
  /// que mostram só "o item" (ex: instruções de retirada).
  MaterialItemModel get primaryItem => items.first;

  String get formattedQuantity {
    final total = totalQuantity;
    final unit = total == 1 ? 'unidade' : 'unidades';
    return '${total.toString().padLeft(2, '0')} $unit';
  }

  String get formattedTime {
    final hour = requestedAt.hour.toString().padLeft(2, '0');
    final minute = requestedAt.minute.toString().padLeft(2, '0');
    return 'Hoje, $hour:$minute';
  }
}
