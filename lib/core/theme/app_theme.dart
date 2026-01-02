import 'package:flutter/material.dart';
import 'tokens.dart';
import 'typography.dart';
import 'motion.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(AppColors.primary),
      primary: const Color(AppColors.primary),
      onPrimary: const Color(AppColors.onPrimary),
      primaryContainer: const Color(AppColors.primaryContainer),
      onPrimaryContainer: const Color(AppColors.onPrimaryContainer),
      secondary: const Color(AppColors.secondary),
      onSecondary: const Color(AppColors.onSecondary),
      secondaryContainer: const Color(AppColors.secondaryContainer),
      onSecondaryContainer: const Color(AppColors.onSecondaryContainer),
      surface: const Color(AppColors.surface),
      onSurface: const Color(AppColors.onSurface),
      surfaceVariant: const Color(AppColors.surfaceVariant),
      onSurfaceVariant: const Color(AppColors.onSurfaceVariant),
      outline: const Color(AppColors.outline),
      outlineVariant: const Color(AppColors.outlineVariant),
      error: const Color(AppColors.error),
      onError: const Color(AppColors.onError),
      errorContainer: const Color(AppColors.errorContainer),
      onErrorContainer: const Color(AppColors.onErrorContainer),
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(AppColors.neutral10),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        backgroundColor: colorScheme.surface,
        indicatorColor: const Color(AppColors.brandTeal).withOpacity(0.18),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          final baseStyle = const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          );
          final color = states.contains(MaterialState.selected)
              ? const Color(AppColors.brandBlue)
              : colorScheme.onSurfaceVariant;
          return baseStyle.copyWith(color: color);
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          final double size = states.contains(MaterialState.selected) ? 28 : 26;
          final Color color = states.contains(MaterialState.selected)
              ? const Color(AppColors.brandBlue)
              : colorScheme.onSurfaceVariant;
          return IconThemeData(size: size, color: color);
        }),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: true,
        elevation: 0,
      ),
      textTheme: AppTypography.light,
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          animationDuration: AppMotion.durationShort,
          overlayColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled))
              return colorScheme.onPrimary.withOpacity(0.06);
            if (states.contains(MaterialState.pressed))
              return colorScheme.onPrimary.withOpacity(0.16);
            if (states.contains(MaterialState.hovered))
              return colorScheme.onPrimary.withOpacity(0.08);
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          animationDuration: AppMotion.durationShort,
          overlayColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled))
              return colorScheme.primary.withOpacity(0.06);
            if (states.contains(MaterialState.pressed))
              return colorScheme.primary.withOpacity(0.12);
            if (states.contains(MaterialState.hovered))
              return colorScheme.primary.withOpacity(0.08);
            return null;
          }),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(AppColors.primary),
      primary: const Color(AppColors.primary),
      onPrimary: const Color(AppColors.onPrimary),
      secondary: const Color(AppColors.secondary),
      onSecondary: const Color(AppColors.onSecondary),
      surface: const Color(0xFF121417),
      onSurface: const Color(AppColors.neutral20),
      error: const Color(AppColors.error),
      brightness: Brightness.dark,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0E1013),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        backgroundColor: colorScheme.surface,
        indicatorColor: const Color(AppColors.brandTeal).withOpacity(0.24),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          final baseStyle = const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          );
          final color = states.contains(MaterialState.selected)
              ? const Color(AppColors.brandBlue)
              : colorScheme.onSurfaceVariant;
          return baseStyle.copyWith(color: color);
        }),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          final double size = states.contains(MaterialState.selected) ? 28 : 26;
          final Color color = states.contains(MaterialState.selected)
              ? const Color(AppColors.brandBlue)
              : colorScheme.onSurfaceVariant;
          return IconThemeData(size: size, color: color);
        }),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: true,
        elevation: 0,
      ),
      textTheme: AppTypography.dark(AppTypography.light),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A1D22),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          animationDuration: AppMotion.durationShort,
          overlayColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled))
              return colorScheme.onPrimary.withOpacity(0.06);
            if (states.contains(MaterialState.pressed))
              return colorScheme.onPrimary.withOpacity(0.16);
            if (states.contains(MaterialState.hovered))
              return colorScheme.onPrimary.withOpacity(0.08);
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          animationDuration: AppMotion.durationShort,
          overlayColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.disabled))
              return colorScheme.primary.withOpacity(0.06);
            if (states.contains(MaterialState.pressed))
              return colorScheme.primary.withOpacity(0.12);
            if (states.contains(MaterialState.hovered))
              return colorScheme.primary.withOpacity(0.08);
            return null;
          }),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
    );
  }
}
