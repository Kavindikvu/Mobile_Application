import 'package:flutter/animation.dart';

class AppMotion {
  AppMotion._();

  static const durationShort = Duration(milliseconds: 150);
  static const durationMedium = Duration(milliseconds: 250);
  static const durationLong = Duration(milliseconds: 400);

  static const curveStandard = Curves.easeInOutCubic;
  static const curveEmphasized = Curves.easeInOutCubicEmphasized;
  static const curveDecelerate = Curves.decelerate;
}


