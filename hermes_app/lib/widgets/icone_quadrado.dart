import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Quadradinho com ícone usado nos cards (itens, salas, categorias).
class IconeQuadrado extends StatelessWidget {
  final IconData icone;
  final bool destaque;
  final double tamanho;

  const IconeQuadrado({super.key, required this.icone, this.destaque = true, this.tamanho = 34});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icone,
        color: destaque ? AppColors.accent : AppColors.textSecondary,
        size: tamanho * 0.5,
      ),
    );
  }
}
