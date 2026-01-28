import 'package:flutter/material.dart';

/// App-wide color definitions for light and dark modes
class AppColors {
  AppColors._();

  // Primary colors
  static const Color primaryLight = Color(0xFF6750A4);
  static const Color primaryDark = Color(0xFFD0BCFF);

  static const Color secondaryLight = Color(0xFF625B71);
  static const Color secondaryDark = Color(0xFFCCC2DC);

  // Status colors
  static const Color errorLight = Color(0xFFB3261E);
  static const Color errorDark = Color(0xFFF2B8B5);

  static const Color successLight = Color(0xFF4CAF50);
  static const Color successDark = Color(0xFF81C784);

  static const Color warningLight = Color(0xFFFF9800);
  static const Color warningDark = Color(0xFFFFB74D);

  // Background colors
  static const Color backgroundLight = Color(0xFFFFFBFE);
  static const Color backgroundDark = Color(0xFF1C1B1F);

  static const Color surfaceLight = Color(0xFFFFFBFE);
  static const Color surfaceDark = Color(0xFF1C1B1F);

  // Text colors
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color onPrimaryDark = Color(0xFF381E72);

  static const Color onBackgroundLight = Color(0xFF1C1B1F);
  static const Color onBackgroundDark = Color(0xFFE6E1E5);

  static const Color onSurfaceLight = Color(0xFF1C1B1F);
  static const Color onSurfaceDark = Color(0xFFE6E1E5);

  // Helper methods
  static Color getPrimary(Brightness brightness) {
    return brightness == Brightness.light ? primaryLight : primaryDark;
  }

  static Color getSecondary(Brightness brightness) {
    return brightness == Brightness.light ? secondaryLight : secondaryDark;
  }

  static Color getError(Brightness brightness) {
    return brightness == Brightness.light ? errorLight : errorDark;
  }

  static Color getSuccess(Brightness brightness) {
    return brightness == Brightness.light ? successLight : successDark;
  }

  static Color getWarning(Brightness brightness) {
    return brightness == Brightness.light ? warningLight : warningDark;
  }
}
