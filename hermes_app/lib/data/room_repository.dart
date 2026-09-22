import 'package:flutter/material.dart';
import '../models/room.dart';

abstract class RoomRepository {
  Future<List<Room>> getRooms();
}

class MockRoomRepository implements RoomRepository {
  static const List<Room> _rooms = [
    Room(
      id: 'sala-101',
      name: 'Sala 101 - T.I.',
      subtitle: 'Bloco A · Central de Hardware',
      floorLabel: 'TÉRREO',
      icon: Icons.dvr_rounded,
    ),
    Room(
      id: 'almoxarifado',
      name: 'Almoxarifado',
      subtitle: 'Bloco B · Depósito Geral',
      floorLabel: 'TÉRREO',
      icon: Icons.inventory_2_rounded,
    ),
    Room(
      id: 'sala-205',
      name: 'Sala 205 - Mecânica',
      subtitle: 'Bloco A · Oficina de Peças',
      floorLabel: '1º ANDAR',
      icon: Icons.build_rounded,
    ),
    Room(
      id: 'lab-robotica',
      name: 'Laboratório de Robótica',
      subtitle: 'Bloco C · P&D',
      floorLabel: '1º ANDAR',
      icon: Icons.smart_toy_rounded,
    ),
    Room(
      id: 'sala-302',
      name: 'Sala 302 - Engenharia',
      subtitle: 'Bloco B · Escritório Técnico',
      floorLabel: '2º ANDAR',
      icon: Icons.architecture_rounded,
    ),
  ];

  @override
  Future<List<Room>> getRooms() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _rooms;
  }
}
