import 'package:flutter/material.dart';
import '../data/order_repository.dart';
import '../data/room_repository.dart';
import '../models/material_category.dart';
import '../models/material_item.dart';
import '../models/room.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_card.dart';
import '../widgets/hermes_app_bar.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_label.dart';
import 'order_approved_screen.dart';

/// Tela 2 do fluxo: escolha da sala/local de destino da entrega.
class SelectRoomScreen extends StatefulWidget {
  final MaterialCategory category;
  final List<MaterialItemModel> items;

  const SelectRoomScreen({
    super.key,
    required this.category,
    required this.items,
  });

  @override
  State<SelectRoomScreen> createState() => _SelectRoomScreenState();
}

class _SelectRoomScreenState extends State<SelectRoomScreen> {
  final RoomRepository _roomRepository = MockRoomRepository();
  final OrderRepository _orderRepository = MockOrderRepository();

  List<Room> _rooms = [];
  Room? _selectedRoom;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    final rooms = await _roomRepository.getRooms();
    if (!mounted) return;
    setState(() {
      _rooms = rooms;
      _selectedRoom = rooms.isNotEmpty ? rooms.first : null;
      _isLoading = false;
    });
  }

  List<Room> get _filteredRooms {
    if (_searchQuery.trim().isEmpty) return _rooms;
    final query = _searchQuery.toLowerCase();
    return _rooms.where((r) => r.name.toLowerCase().contains(query)).toList();
  }

  Map<String, List<Room>> get _groupedRooms {
    final Map<String, List<Room>> groups = {};
    for (final room in _filteredRooms) {
      groups.putIfAbsent(room.floorLabel, () => []).add(room);
    }
    return groups;
  }

  Future<void> _onConfirmDestination() async {
    if (_selectedRoom == null || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    final order = await _orderRepository.submitOrder(
      category: widget.category,
      items: widget.items,
      room: _selectedRoom!,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderApprovedScreen(order: order)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HermesAppBar(stageBadge: 'Destino'),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      children: [
                        const Text('Selecione a Sala', style: AppTextStyles.screenTitle),
                        const SizedBox(height: 6),
                        const Text(
                          'Escolha o local de destino para a entrega dos materiais.',
                          style: AppTextStyles.screenSubtitle,
                        ),
                        const SizedBox(height: 20),
                        const SectionLabel('Buscar no terminal'),
                        const SizedBox(height: 8),
                        _SearchField(
                          hint: 'Ex: Sala 101, Almoxarifado...',
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                        const SizedBox(height: 20),
                        for (final floor in _groupedRooms.keys) ...[
                          SectionLabel(floor),
                          const SizedBox(height: 10),
                          for (final room in _groupedRooms[floor]!)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _RoomTile(
                                room: room,
                                selected: room.id == _selectedRoom?.id,
                                onTap: () => setState(() => _selectedRoom = room),
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: PrimaryButton(
                label: 'Confirmar Destino',
                icon: Icons.check_rounded,
                isLoading: _isSubmitting,
                onPressed: _selectedRoom != null ? _onConfirmDestination : null,
              ),
            ),
          ],
        ),
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

class _RoomTile extends StatelessWidget {
  final Room room;
  final bool selected;
  final VoidCallback onTap;

  const _RoomTile({
    required this.room,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      borderColor: selected ? AppColors.accent : AppColors.border,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
            child: Icon(
              room.icon,
              color: selected ? AppColors.accent : AppColors.textSecondary,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.name, style: AppTextStyles.cardTitle),
                const SizedBox(height: 2),
                Text(room.subtitle, style: AppTextStyles.cardSubtitle),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _RadioIndicator(selected: selected),
        ],
      ),
    );
  }
}

class _RadioIndicator extends StatelessWidget {
  final bool selected;
  const _RadioIndicator({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.accent : AppColors.border,
          width: 1.6,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent,
                ),
              ),
            )
          : null,
    );
  }
}
