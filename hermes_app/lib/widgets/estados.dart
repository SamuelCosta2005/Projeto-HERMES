import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/erros.dart';

class EstadoCarregando extends StatelessWidget {
  const EstadoCarregando({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator(color: AppColors.accent));
  }
}

class EstadoVazio extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String? subtitulo;

  const EstadoVazio({super.key, required this.icone, required this.titulo, this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, color: AppColors.textMuted, size: 40),
            const SizedBox(height: 12),
            Text(titulo, style: AppTextStyles.cardTitle, textAlign: TextAlign.center),
            if (subtitulo != null) ...[
              const SizedBox(height: 6),
              Text(subtitulo!, style: AppTextStyles.cardSubtitle, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

class EstadoErro extends StatelessWidget {
  final Object erro;
  final VoidCallback? onTentarNovamente;

  const EstadoErro({super.key, required this.erro, this.onTentarNovamente});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.warning, size: 40),
            const SizedBox(height: 12),
            Text(mensagemDeErro(erro), style: AppTextStyles.cardSubtitle, textAlign: TextAlign.center),
            if (onTentarNovamente != null) ...[
              const SizedBox(height: 14),
              TextButton(
                onPressed: onTentarNovamente,
                child: Text(
                  'Tentar de novo',
                  style: AppTextStyles.body.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
