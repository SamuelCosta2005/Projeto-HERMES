import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/erros.dart';

/// Pergunta de confirmação. Devolve true se o usuário confirmou.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String textoConfirmar = 'Confirmar',
  bool destrutivo = false,
}) async {
  final resposta = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(titulo, style: AppTextStyles.cardTitle.copyWith(fontSize: 16)),
      content: Text(mensagem, style: AppTextStyles.cardSubtitle.copyWith(fontSize: 13)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Cancelar', style: AppTextStyles.body),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(
            textoConfirmar,
            style: AppTextStyles.body.copyWith(
              color: destrutivo ? AppColors.warning : AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  return resposta == true;
}

void mostrarErro(BuildContext context, Object erro) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.warning,
        content: Text(mensagemDeErro(erro), style: const TextStyle(color: Colors.white)),
      ),
    );
}

void mostrarAviso(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.surface,
        content: Text(mensagem, style: AppTextStyles.body),
      ),
    );
}
