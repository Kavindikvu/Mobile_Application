import 'package:flutter/services.dart';

class AppHaptics {
  AppHaptics._();

  static Future<void> lightImpact() => HapticFeedback.lightImpact();
  static Future<void> mediumImpact() => HapticFeedback.mediumImpact();
  static Future<void> heavyImpact() => HapticFeedback.heavyImpact();
  static Future<void> selectionClick() => HapticFeedback.selectionClick();
}


