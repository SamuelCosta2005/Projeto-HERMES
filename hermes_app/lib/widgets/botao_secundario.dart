import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Botão de contorno (ações secundárias), no mesmo formato do botão principal.
class BotaoSecundario extends StatelessWidget {
  final String rotulo;
  final IconData icone;
  final VoidCallback? onPressed;
  final bool destrutivo;
  final bool carregando;

  const BotaoSecundario({
    super.key,
    required this.rotulo,
    required this.icone,
    required this.onPressed,
    this.destrutivo = false,
    this.carregando = false,
  });

  @override
  Widget build(BuildContext context) {
    final cor = destrutivo ? AppColors.warning : AppColors.accent;
    final ativo = onPressed != null && !carregando;
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: ativo ? onPressed : null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: ativo ? cor : AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: carregando
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: cor),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icone, size: 18, color: ativo ? cor : AppColors.textMuted),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      rotulo,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardTitle.copyWith(
                        fontSize: 13.5,
                        color: ativo ? cor : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
