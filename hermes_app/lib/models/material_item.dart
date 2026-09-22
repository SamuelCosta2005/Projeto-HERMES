import 'package:flutter/material.dart';

/// Representa um item do estoque (ex: Cabo Ethernet Cat6 5m).
///
/// [quantity] é mutável de propósito: é a quantidade que o usuário
/// selecionou na tela de materiais (controlada pelos botões -/+).
class MaterialItemModel {
  final String id;
  final String categoryId;
  final String name;
  final int stock;
  final IconData icon;
  int quantity;

  MaterialItemModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.stock,
    required this.icon,
    this.quantity = 0,
  });

  MaterialItemModel copyWith({int? quantity}) {
    return MaterialItemModel(
      id: id,
      categoryId: categoryId,
      name: name,
      stock: stock,
      icon: icon,
      quantity: quantity ?? this.quantity,
    );
  }
}
