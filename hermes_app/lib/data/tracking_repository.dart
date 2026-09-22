import '../models/order_details.dart';
import '../models/tracking_status.dart';

abstract class TrackingRepository {
  Future<TrackingStatus> getTracking(OrderDetails order);
}

class MockTrackingRepository implements TrackingRepository {
  @override
  Future<TrackingStatus> getTracking(OrderDetails order) async {
    await Future.delayed(const Duration(milliseconds: 350));

    return const TrackingStatus(
      buildingLabel: 'MAPA DA FILIAL (PRÉDIO INDUSTRIAL 4)',
      robotLabel: 'HERMES V2 NO CORREDOR 3',
      originLabel: 'DEPÓSITO (A)',
      destinationLabel: 'VOCÊ (SETOR B)',
      statusText: 'A caminho do Setor B',
      etaText: '4 Minutos',
      progress: 0.65,
    );
  }
}
