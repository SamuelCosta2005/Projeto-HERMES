import '../models/order_details.dart';
import '../models/queue_entry.dart';

abstract class QueueRepository {
  Future<QueueStatus> getQueueStatus(OrderDetails order);
}

class MockQueueRepository implements QueueRepository {
  @override
  Future<QueueStatus> getQueueStatus(OrderDetails order) async {
    await Future.delayed(const Duration(milliseconds: 350));

    return QueueStatus(
      myPosition: 3,
      waitMinutes: 8,
      route: [
        const QueueEntry(
          position: 1,
          orderCode: '#HR-8939',
          destination: 'Mecânica · Setor A',
          statusLabel: 'Em rota',
        ),
        const QueueEntry(
          position: 2,
          orderCode: '#HR-8940',
          destination: 'T.I. · Setor C',
          statusLabel: 'Próximo',
        ),
        QueueEntry(
          position: 3,
          orderCode: order.code,
          destination: 'Você · ${order.room.name.split(' - ').last}',
          statusLabel: 'Foco',
          isMine: true,
        ),
        const QueueEntry(
          position: 4,
          orderCode: '#HR-8942',
          destination: 'Mecânica · Setor B',
          statusLabel: 'Aguardando',
        ),
      ],
    );
  }
}
