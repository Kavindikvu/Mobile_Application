import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static TextTheme light = const TextTheme(
    displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400, height: 1.12),
    displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400, height: 1.16),
    displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400, height: 1.22),
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, height: 1.25),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.28),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, height: 1.33),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.27),
    titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.50),
    titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.43),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.55),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.50),
    bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.38),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.43, letterSpacing: 0.1),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, height: 1.33, letterSpacing: 0.4),
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.27, letterSpacing: 0.4),
  );

  static TextTheme dark(TextTheme base) {
    // Slight adjustments can be made if needed; here we reuse base
    return base;
  }
}


