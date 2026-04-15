import 'package:flutter/material.dart';

/// Warna yang berubah mengikuti tema (light/dark).
/// Gunakan via extension: `context.appColors.card`
///
/// Warna brand yang tidak berubah (brandBlue, positive, negative)
/// tetap diakses langsung dari [AppColors].
class AppDynamicColors {
  const AppDynamicColors._({
    required this.card,
    required this.cardSoft,
    required this.chipBg,
    required this.outline,
    required this.textPrimary,
    required this.textSecondary,
    required this.backgroundBottom,
  });

  final Color card;
  final Color cardSoft;
  final Color chipBg;
  final Color outline;
  final Color textPrimary;
  final Color textSecondary;
  final Color backgroundBottom;

  static const dark = AppDynamicColors._(
    card: Color(0xFF111B26),
    cardSoft: Color(0xFF0E1722),
    chipBg: Color(0xFF162232),
    outline: Color(0xFF2A3A4A),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF8FA0B3),
    backgroundBottom: Color(0xFF040A12),
  );

  static const light = AppDynamicColors._(
    card: Color(0xFFFFFFFF),
    cardSoft: Color(0xFFF1F5F9),
    chipBg: Color(0xFFE8EEF8),
    outline: Color(0xFFDDE3EE),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    backgroundBottom: Color(0xFFEAEFF8),
  );
}

extension AppDynamicColorsContext on BuildContext {
  AppDynamicColors get appColors {
    return Theme.of(this).brightness == Brightness.dark
        ? AppDynamicColors.dark
        : AppDynamicColors.light;
  }
}
