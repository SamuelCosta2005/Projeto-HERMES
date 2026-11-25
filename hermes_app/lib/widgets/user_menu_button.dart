import 'package:flutter/material.dart';
import '../models/perfil.dart';
import '../services/auth_service.dart';
import '../services/sessao.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Ícone da conta: mostra nome e papel e permite sair.
class UserMenuButton extends StatelessWidget {
  const UserMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Perfil?>(
      valueListenable: Sessao.perfil,
      builder: (context, perfil, _) {
        if (perfil == null) return const SizedBox.shrink();
        return PopupMenuButton<String>(
          tooltip: 'Conta',
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.border),
          ),
          onSelected: (valor) {
            if (valor == 'sair') AuthService.sair();
          },
          itemBuilder: (context) => [
            PopupMenuItem<String>(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(perfil.nome, style: AppTextStyles.cardTitle),
                  Text(perfil.papel.rotulo, style: AppTextStyles.cardSubtitle),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'sair',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, color: AppColors.warning, size: 18),
                  const SizedBox(width: 10),
                  Text('Sair', style: AppTextStyles.body),
                ],
              ),
            ),
          ],
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceAlt,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(Icons.person_rounded, color: AppColors.textSecondary, size: 18),
          ),
        );
      },
    );
  }
}
