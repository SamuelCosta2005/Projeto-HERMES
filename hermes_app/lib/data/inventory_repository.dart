import 'package:flutter/material.dart';
import '../models/material_category.dart';
import '../models/material_item.dart';

/// Contrato de acesso aos dados de estoque.
///
/// Hoje só existe [MockInventoryRepository], mas quando houver uma API real
/// basta criar, por exemplo, `ApiInventoryRepository implements InventoryRepository`
/// e trocar a instância usada nas telas — nenhuma tela precisa mudar.
abstract class InventoryRepository {
  Future<List<MaterialCategory>> getCategories();
  Future<List<MaterialItemModel>> getItemsByCategory(String categoryId);
}

class MockInventoryRepository implements InventoryRepository {
  static final List<MaterialCategory> _categories = [
    const MaterialCategory(
      id: 'ti',
      name: 'T.I.',
      subtitle: 'Hardware e Acessórios',
      icon: Icons.computer_rounded,
    ),
    const MaterialCategory(
      id: 'mecanica',
      name: 'Mecânica',
      subtitle: 'Ferramentas e Peças',
      icon: Icons.build_rounded,
    ),
  ];

  static final Map<String, List<MaterialItemModel>> _itemsByCategory = {
    'ti': [
      MaterialItemModel(
        id: 'cabo-cat6',
        categoryId: 'ti',
        name: 'Cabo Ethernet Cat6 5m',
        stock: 14,
        icon: Icons.cable_rounded,
      ),
      MaterialItemModel(
        id: 'mouse-optico',
        categoryId: 'ti',
        name: 'Mouse Óptico USB',
        stock: 8,
        icon: Icons.mouse_rounded,
      ),
      MaterialItemModel(
        id: 'adaptador-hdmi',
        categoryId: 'ti',
        name: 'Adaptador HDMI para VGA',
        stock: 3,
        icon: Icons.settings_input_hdmi_rounded,
      ),
    ],
    'mecanica': [
      MaterialItemModel(
        id: 'chave-fenda',
        categoryId: 'mecanica',
        name: 'Chave de Fenda Phillips',
        stock: 22,
        icon: Icons.build_rounded,
      ),
      MaterialItemModel(
        id: 'parafuso-m8',
        categoryId: 'mecanica',
        name: 'Parafuso M8 (cx. 100un)',
        stock: 6,
        icon: Icons.settings_rounded,
      ),
      MaterialItemModel(
        id: 'furadeira',
        categoryId: 'mecanica',
        name: 'Furadeira de Bancada',
        stock: 2,
        icon: Icons.handyman_rounded,
      ),
    ],
  };

  @override
  Future<List<MaterialCategory>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _categories;
  }

  @override
  Future<List<MaterialItemModel>> getItemsByCategory(String categoryId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _itemsByCategory[categoryId] ?? const [];
  }
}
