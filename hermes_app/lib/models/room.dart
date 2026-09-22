import 'package:flutter/material.dart';

/// Representa uma sala/local que pode ser escolhido como destino de entrega.
class Room {
  final String id;
  final String name;
  final String subtitle;
  final String floorLabel; // Ex: "TÉRREO", "1º ANDAR", "2º ANDAR"
  final IconData icon;

  const Room({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.floorLabel,
    required this.icon,
  });
}
