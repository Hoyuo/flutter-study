import 'package:flutter/material.dart';

/// Task priority levels
enum Priority {
  high(3, 'High', Color(0xFFEF4444)),
  medium(2, 'Medium', Color(0xFFF59E0B)),
  low(1, 'Low', Color(0xFF22C55E));

  const Priority(this.value, this.label, this.color);

  final int value;
  final String label;
  final Color color;

  /// Get priority from int value
  static Priority fromValue(int value) {
    return Priority.values.firstWhere(
      (p) => p.value == value,
      orElse: () => Priority.medium,
    );
  }
}
