import 'package:flutter/material.dart';

/// Utility class for color operations
class ColorUtils {
  ColorUtils._();

  /// Parse a hex color string to Color
  /// Returns grey if parsing fails
  static Color parseHex(String? hexCode) {
    if (hexCode == null || hexCode.isEmpty) {
      return Colors.grey;
    }
    try {
      final hex = hexCode.startsWith('#') ? hexCode.substring(1) : hexCode;
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }
}
