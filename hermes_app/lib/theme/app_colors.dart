import 'package:flutter/material.dart';

/// Paleta de cores do app Hermes.
/// Centralizar aqui facilita trocar o visual do app inteiro em um só lugar.
class AppColors {
  AppColors._();

  // Fundo
  static const Color background = Color(0xFF0A0E14);
  static const Color surface = Color(0xFF141A22);
  static const Color surfaceAlt = Color(0xFF10151C);
  static const Color border = Color(0xFF232C38);

  // Texto
  static const Color textPrimary = Color(0xFFF3F6FA);
  static const Color textSecondary = Color(0xFF8B96A8);
  static const Color textMuted = Color(0xFF5C6678);

  // Cor de destaque (ciano) - ação primária, seleção, links
  static const Color accent = Color(0xFF22D3EE);
  static const Color accentDim = Color(0xFF0E7C90);
  static const Color accentBackground = Color(0x1A22D3EE); // 10% opacidade

  // Sucesso (verde) - aprovação, confirmação final
  static const Color success = Color(0xFF22C55E);
  static const Color successBackground = Color(0x1A22C55E);
  static const Color successDark = Color(0xFF0F2E1C);

  // Utilitários
  static const Color divider = Color(0xFF1D2530);
  static const Color shadow = Color(0x662BE8F1);
}
