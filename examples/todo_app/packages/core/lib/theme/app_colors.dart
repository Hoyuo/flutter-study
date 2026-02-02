import 'package:flutter/material.dart';

/// App color palette based on DESIGN_SPEC.md
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF8B5CF6);
  static const Color primaryLight = Color(0x208B5CF6);

  // Category Colors
  static const Color purple = Color(0xFF8B5CF6);
  static const Color teal = Color(0xFF14B8A6);
  static const Color pink = Color(0xFFF472B6);
  static const Color orange = Color(0xFFF59E0B);
  static const Color red = Color(0xFFEF4444);
  static const Color indigo = Color(0xFF6366F1);

  // Light Theme Colors
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF4F4F5); // Gray 100
  static const Color onBackgroundLight = Color(0xFF18181B); // Gray 900
  static const Color onSurfaceLight = Color(0xFF18181B); // Gray 900
  static const Color secondaryTextLight = Color(0xFF71717A); // Gray 500
  static const Color tertiaryTextLight = Color(0xFFA1A1AA); // Gray 400

  // Dark Theme Colors
  static const Color backgroundDark = Color(0xFF0F0F10);
  static const Color surfaceDark = Color(0xFF27272A); // Gray 700
  static const Color modalBackgroundDark = Color(0xFF18181B); // Gray 800
  static const Color borderDark = Color(0xFF52525B); // Gray 600
  static const Color onBackgroundDark = Color(0xFFFFFFFF);
  static const Color onSurfaceDark = Color(0xFFFFFFFF);
  static const Color secondaryTextDark = Color(0xFF71717A); // Gray 500

  // Semantic Colors
  static const Color success = Color(0xFF22C55E);
  static const Color successBackground = Color(0xFFDCFCE7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBackground = Color(0xFFFEE2E2);

  // Category color list
  static const List<Color> categoryColors = [
    purple,
    teal,
    pink,
    orange,
    red,
    indigo,
  ];

  /// Get color from hex string
  static Color fromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Convert color to hex string
  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}
