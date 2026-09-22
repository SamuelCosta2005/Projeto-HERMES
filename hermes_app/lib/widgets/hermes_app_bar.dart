import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Cabeçalho padrão do app: logo "HERMES" à esquerda e um selo indicando
/// a etapa atual do fluxo à direita (ex: "DESTINO", "FILA", "CHEGOU").
class HermesAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String stageBadge;

  const HermesAppBar({super.key, required this.stageBadge});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent, width: 1.4),
                color: AppColors.accentBackground,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.accent,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            const Text('HERMES', style: AppTextStyles.logo),
            const Spacer(),
            Text(stageBadge.toUpperCase(), style: AppTextStyles.badge),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
