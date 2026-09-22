import 'dart:math';
import '../models/material_category.dart';
import '../models/material_item.dart';
import '../models/order_details.dart';
import '../models/room.dart';

abstract class OrderRepository {
  Future<OrderDetails> submitOrder({
    required MaterialCategory category,
    required List<MaterialItemModel> items,
    required Room room,
  });
}

class MockOrderRepository implements OrderRepository {
  final Random _random = Random();

  @override
  Future<OrderDetails> submitOrder({
    required MaterialCategory category,
    required List<MaterialItemModel> items,
    required Room room,
  }) async {
    // Simula a validação das credenciais do terminal / autenticação.
    await Future.delayed(const Duration(milliseconds: 600));

    final code = '#HR-${1000 + _random.nextInt(9000)}';

    return OrderDetails(
      code: code,
      category: category,
      items: items,
      room: room,
      requesterName: 'Roberto Silva',
      requesterSector: 'Engenharia',
      requestedAt: DateTime.now(),
      etaMinutes: 10 + _random.nextInt(6), // 10 a 15 minutos
    );
  }
}
