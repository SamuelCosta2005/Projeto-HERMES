import 'package:flutter/material.dart';

/// Um conjunto completo de cores para um modo (claro ou escuro).
///
/// Cada modo é uma const separada — isso é o que permite ao [AppColors]
/// trocar tudo instantaneamente sem precisar recalcular nada em tempo real.
class _Palette {
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color accentDim;
  final Color accentBackground;
  final Color success;
  final Color successBackground;
  final Color successDark;
  final Color warning;
  final Color warningBackground;
  final Color divider;
  final Color shadow;

  const _Palette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.accentDim,
    required this.accentBackground,
    required this.success,
    required this.successBackground,
    required this.successDark,
    required this.warning,
    required this.warningBackground,
    required this.divider,
    required this.shadow,
  });

  // Tema escuro original do app (ciano).
  static const dark = _Palette(
    background: Color(0xFF0A0E14),
    surface: Color(0xFF141A22),
    surfaceAlt: Color(0xFF10151C),
    border: Color(0xFF232C38),
    textPrimary: Color(0xFFF3F6FA),
    textSecondary: Color(0xFF8B96A8),
    textMuted: Color(0xFF5C6678),
    accent: Color(0xFF22D3EE),
    accentDim: Color(0xFF0E7C90),
    accentBackground: Color(0x1A22D3EE), // 10% opacidade
    success: Color(0xFF22C55E),
    successBackground: Color(0x1A22C55E),
    successDark: Color(0xFF0F2E1C),
    warning: Color(0xFFEF4444),
    warningBackground: Color(0x1AEF4444),
    divider: Color(0xFF1D2530),
    shadow: Color(0x662BE8F1),
  );

  // Tema claro pedido pelo cliente: primária branca, secundária laranja.
  static const light = _Palette(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF6F7F9),
    surfaceAlt: Color(0xFFEDEFF3),
    border: Color(0xFFE3E6EC),
    textPrimary: Color(0xFF15181D),
    textSecondary: Color(0xFF5B6472),
    textMuted: Color(0xFF9AA2AF),
    accent: Color(0xFFFF7A1A), // laranja
    accentDim: Color(0xFFC85E10),
    accentBackground: Color(0x1FFF7A1A), // ~12% opacidade
    success: Color(0xFF16A34A),
    successBackground: Color(0x1A16A34A),
    successDark: Color(0xFFE8F8EE),
    warning: Color(0xFFDC2626),
    warningBackground: Color(0x1ADC2626),
    divider: Color(0xFFE9EBF0),
    shadow: Color(0x33FF7A1A),
  );
}

/// Paleta de cores do app Hermes.
///
/// Fica escutável via [themeMode]: quando o usuário aperta o botão de
/// sol/lua, o valor muda e o app inteiro é reconstruído com a nova paleta.
/// Todo o resto do app continua acessando cores normalmente, ex:
/// `AppColors.background`, `AppColors.accent` — só que agora o valor
/// devolvido depende do modo atual.
class AppColors {
  AppColors._();

  /// true = tema escuro (padrão original), false = tema claro.
  static final ValueNotifier<bool> themeIsDark = ValueNotifier<bool>(true);

  static void toggleTheme() {
    themeIsDark.value = !themeIsDark.value;
  }

  static _Palette get _p => themeIsDark.value ? _Palette.dark : _Palette.light;

  static Color get background => _p.background;
  static Color get surface => _p.surface;
  static Color get surfaceAlt => _p.surfaceAlt;
  static Color get border => _p.border;

  static Color get textPrimary => _p.textPrimary;
  static Color get textSecondary => _p.textSecondary;
  static Color get textMuted => _p.textMuted;

  static Color get accent => _p.accent;
  static Color get accentDim => _p.accentDim;
  static Color get accentBackground => _p.accentBackground;

  static Color get success => _p.success;
  static Color get successBackground => _p.successBackground;
  static Color get successDark => _p.successDark;
  static Color get warning => _p.warning;
  static Color get warningBackground => _p.warningBackground;

  static Color get divider => _p.divider;
  static Color get shadow => _p.shadow;
}
