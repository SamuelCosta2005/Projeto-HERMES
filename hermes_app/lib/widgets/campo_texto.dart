import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Campo de texto no estilo do app (mesma caixa dos campos de busca do Hermes).
class CampoTexto extends StatelessWidget {
  final TextEditingController controller;
  final String? rotulo;
  final String? dica;
  final IconData? icone;
  final bool obscuro;
  final TextInputType? teclado;
  final TextInputAction? acao;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onEnviar;
  final List<TextInputFormatter>? formatadores;
  final int linhas;
  final bool habilitado;
  final bool autofoco;

  const CampoTexto({
    super.key,
    required this.controller,
    this.rotulo,
    this.dica,
    this.icone,
    this.obscuro = false,
    this.teclado,
    this.acao,
    this.onChanged,
    this.onEnviar,
    this.formatadores,
    this.linhas = 1,
    this.habilitado = true,
    this.autofoco = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rotulo != null) ...[
          Text(rotulo!, style: AppTextStyles.cardSubtitle),
          const SizedBox(height: 6),
        ],
        Container(
          decoration: BoxDecoration(
            color: habilitado ? AppColors.surface : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: controller,
            enabled: habilitado,
            autofocus: autofoco,
            obscureText: obscuro,
            keyboardType: teclado,
            textInputAction: acao,
            onChanged: onChanged,
            onSubmitted: onEnviar,
            inputFormatters: formatadores,
            maxLines: obscuro ? 1 : linhas,
            style: AppTextStyles.body,
            cursorColor: AppColors.accent,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: dica,
              hintStyle: AppTextStyles.cardSubtitle,
              prefixIcon: icone == null ? null : Icon(icone, color: AppColors.textMuted, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
