import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Controle "- 1 +" (igual ao da tela de materiais do Hermes).
class StepperQuantidade extends StatelessWidget {
  final int valor;
  final VoidCallback? onMenos;
  final VoidCallback? onMais;

  const StepperQuantidade({super.key, required this.valor, required this.onMenos, required this.onMais});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Botao(icone: Icons.remove_rounded, onTap: onMenos),
        Container(
          width: 30,
          alignment: Alignment.center,
          child: Text(
            '$valor',
            style: AppTextStyles.cardTitle.copyWith(
              color: valor > 0 ? AppColors.accent : AppColors.textPrimary,
            ),
          ),
        ),
        _Botao(icone: Icons.add_rounded, onTap: onMais),
      ],
    );
  }
}

class _Botao extends StatelessWidget {
  final IconData icone;
  final VoidCallback? onTap;

  const _Botao({required this.icone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(
            icone,
            size: 17,
            color: onTap == null ? AppColors.textMuted : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
