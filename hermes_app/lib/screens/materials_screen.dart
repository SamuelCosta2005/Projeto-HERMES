import 'package:flutter/material.dart';
import '../data/inventory_repository.dart';
import '../models/material_category.dart';
import '../models/material_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/hermes_app_bar.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_label.dart';
import 'select_room_screen.dart';

/// Tela 1 do fluxo: escolha da categoria + itens e quantidades desejadas.
class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final InventoryRepository _repository = MockInventoryRepository();

  List<MaterialCategory> _categories = [];
  List<MaterialItemModel> _items = [];
  MaterialCategory? _selectedCategory;
  bool _isLoadingCategories = true;
  bool _isLoadingItems = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await _repository.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _selectedCategory = categories.isNotEmpty ? categories.first : null;
      _isLoadingCategories = false;
    });
    if (_selectedCategory != null) {
      _loadItems(_selectedCategory!.id);
    }
  }

  Future<void> _loadItems(String categoryId) async {
    setState(() => _isLoadingItems = true);
    final items = await _repository.getItemsByCategory(categoryId);
    if (!mounted) return;
    setState(() {
      _items = items;
      _isLoadingItems = false;
    });
  }

  void _onCategoryTap(MaterialCategory category) {
    if (category.id == _selectedCategory?.id) return;
    setState(() => _selectedCategory = category);
    _loadItems(category.id);
  }

  void _changeQuantity(MaterialItemModel item, int delta) {
    setState(() {
      final newQty = (item.quantity + delta).clamp(0, item.stock);
      item.quantity = newQty;
    });
  }

  List<MaterialItemModel> get _filteredItems {
    if (_searchQuery.trim().isEmpty) return _items;
    final query = _searchQuery.toLowerCase();
    return _items.where((i) => i.name.toLowerCase().contains(query)).toList();
  }

  List<MaterialItemModel> get _selectedItems =>
      _items.where((i) => i.quantity > 0).toList();

  void _onRequestDelivery() {
    if (_selectedCategory == null || _selectedItems.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SelectRoomScreen(
          category: _selectedCategory!,
          items: _selectedItems,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _selectedItems.isNotEmpty;

    return Scaffold(
      appBar: const HermesAppBar(stageBadge: 'Selecionar'),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: _isLoadingCategories
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      children: [
                        Row(
                          children: _categories
                              .map(
                                (c) => Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: c == _categories.last ? 0 : 12,
                                    ),
                                    child: _CategoryCard(
                                      category: c,
                                      selected: c.id == _selectedCategory?.id,
                                      onTap: () => _onCategoryTap(c),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 22),
                        const SectionLabel('Buscar no estoque'),
                        const SizedBox(height: 8),
                        _SearchField(
                          hint: 'Ex: Cabo HDMI, Teclado, Parafuso M8...',
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                        const SizedBox(height: 22),
                        const SectionLabel('Recentes / Populares'),
                        const SizedBox(height: 10),
                        if (_isLoadingItems)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.accent,
                              ),
                            ),
                          )
                        else if (_filteredItems.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'Nenhum item encontrado.',
                                style: AppTextStyles.cardSubtitle,
                              ),
                            ),
                          )
                        else
                          ..._filteredItems.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ItemRow(
                                item: item,
                                onDecrement: () => _changeQuantity(item, -1),
                                onIncrement: () => _changeQuantity(item, 1),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: PrimaryButton(
                label: 'Solicitar Entrega',
                icon: Icons.local_shipping_rounded,
                onPressed: canSubmit ? _onRequestDelivery : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final MaterialCategory category;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      borderColor: selected ? AppColors.accent : AppColors.border,
      backgroundColor: selected ? AppColors.accentBackground : AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              category.icon,
              color: selected ? AppColors.accent : AppColors.textSecondary,
              size: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(category.name, style: AppTextStyles.cardTitle),
          const SizedBox(height: 2),
          Text(
            category.subtitle,
            style: AppTextStyles.cardSubtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        onChanged: onChanged,
        style: AppTextStyles.body,
        cursorColor: AppColors.accent,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: AppTextStyles.cardSubtitle,
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final MaterialItemModel item;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _ItemRow({
    required this.item,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: AppColors.accent, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: AppTextStyles.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text('Estoque: ${item.stock} un', style: AppTextStyles.cardSubtitle),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _QuantityStepper(
            quantity: item.quantity,
            onDecrement: onDecrement,
            onIncrement: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperButton(icon: Icons.remove_rounded, onTap: onDecrement),
        Container(
          width: 28,
          alignment: Alignment.center,
          child: Text(
            '$quantity',
            style: AppTextStyles.cardTitle.copyWith(
              color: quantity > 0 ? AppColors.accent : AppColors.textPrimary,
            ),
          ),
        ),
        _StepperButton(icon: Icons.add_rounded, onTap: onIncrement),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(icon, size: 16, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
