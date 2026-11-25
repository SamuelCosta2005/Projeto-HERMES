import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'theme_toggle_button.dart';
import 'user_menu_button.dart';

/// Cabeçalho padrão (mesmo visual do Hermes original): logo à esquerda, selo da
/// etapa atual à direita, menu da conta e botão de sol/lua.
class HermesAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String stageBadge;
  final bool mostrarUsuario;

  const HermesAppBar({super.key, required this.stageBadge, this.mostrarUsuario = true});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
        child: Row(
          children: [
            // Botão de voltar: aparece sozinho em toda tela que foi aberta por cima de outra.
            if (Navigator.of(context).canPop()) ...[
              InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 22),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.accent, width: 1.4),
                color: AppColors.accentBackground,
              ),
              child: Icon(Icons.inventory_2_outlined, color: AppColors.accent, size: 16),
            ),
            const SizedBox(width: 10),
            Text('HERMES', style: AppTextStyles.logo),
            const SizedBox(width: 12),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  stageBadge.toUpperCase(),
                  style: AppTextStyles.badge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (mostrarUsuario) ...[
              UserMenuButton(),
              const SizedBox(width: 8),
            ],
            ThemeToggleButton(),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
