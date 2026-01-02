import 'package:flutter/material.dart';

/// Global key used to surface SnackBars without needing a BuildContext.
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

enum AppToastType { success, warning, error, info }

class AppToast {
  const AppToast._();

  static void success(String message) {
    show(message: message, type: AppToastType.success);
  }

  static void warning(String message) {
    show(message: message, type: AppToastType.warning);
  }

  static void error(String message) {
    show(message: message, type: AppToastType.error);
  }

  static void info(String message) {
    show(message: message, type: AppToastType.info);
  }

  static void show({
    required String message,
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messengerState = appScaffoldMessengerKey.currentState;
    final context = appScaffoldMessengerKey.currentContext;
    if (messengerState == null || context == null) {
      return;
    }

    final colors = Theme.of(context).colorScheme;
    final (backgroundColor, icon, textColor) = switch (type) {
      AppToastType.success => (
          colors.tertiaryContainer,
          Icons.check_circle,
          colors.onTertiaryContainer,
        ),
      AppToastType.warning => (
          colors.secondaryContainer,
          Icons.info_outline,
          colors.onSecondaryContainer,
        ),
      AppToastType.error => (
          colors.errorContainer,
          Icons.error_outline,
          colors.onErrorContainer,
        ),
      AppToastType.info => (
          colors.surfaceVariant,
          Icons.info_outline,
          colors.onSurfaceVariant,
        ),
    };

    messengerState
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: textColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: textColor),
                ),
              ),
            ],
          ),
          duration: duration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor,
          elevation: 0,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
  }

  /// Shows a toast for API failures. Falls back to a generic copy for 5xx codes.
  static void showApiError({
    required int statusCode,
    String? message,
  }) {
    final trimmed = message?.trim();
    final effectiveMessage = (statusCode >= 500 || (trimmed?.isEmpty ?? true))
        ? 'We\'re experiencing issues right now. Please try again shortly.'
        : trimmed!;
    error(effectiveMessage);
  }
}

