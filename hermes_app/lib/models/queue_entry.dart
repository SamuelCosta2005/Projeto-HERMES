/// Um item dentro da rota de entregas do robô (tela "Fila").
class QueueEntry {
  final int position;
  final String orderCode;
  final String destination;
  final String statusLabel; // "Em rota", "Próximo", "Aguardando"...
  final bool isMine;

  const QueueEntry({
    required this.position,
    required this.orderCode,
    required this.destination,
    required this.statusLabel,
    this.isMine = false,
  });
}

/// Estado geral da fila para o pedido do usuário atual.
class QueueStatus {
  final int myPosition;
  final int waitMinutes;
  final List<QueueEntry> route;

  const QueueStatus({
    required this.myPosition,
    required this.waitMinutes,
    required this.route,
  });
}
