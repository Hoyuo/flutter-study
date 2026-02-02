import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/types/priority.dart';

void main() {
  group('Priority', () {
    group('enum values', () {
      test('should have correct number of priorities', () {
        expect(Priority.values.length, 3);
      });

      test('should have high priority with correct properties', () {
        expect(Priority.high.value, 3);
        expect(Priority.high.label, 'High');
        expect(Priority.high.color, const Color(0xFFEF4444));
      });

      test('should have medium priority with correct properties', () {
        expect(Priority.medium.value, 2);
        expect(Priority.medium.label, 'Medium');
        expect(Priority.medium.color, const Color(0xFFF59E0B));
      });

      test('should have low priority with correct properties', () {
        expect(Priority.low.value, 1);
        expect(Priority.low.label, 'Low');
        expect(Priority.low.color, const Color(0xFF22C55E));
      });

      test('should maintain enum order', () {
        expect(Priority.values[0], Priority.high);
        expect(Priority.values[1], Priority.medium);
        expect(Priority.values[2], Priority.low);
      });
    });

    group('fromValue', () {
      test('should return high priority for value 3', () {
        final priority = Priority.fromValue(3);
        expect(priority, Priority.high);
        expect(priority.value, 3);
        expect(priority.label, 'High');
      });

      test('should return medium priority for value 2', () {
        final priority = Priority.fromValue(2);
        expect(priority, Priority.medium);
        expect(priority.value, 2);
        expect(priority.label, 'Medium');
      });

      test('should return low priority for value 1', () {
        final priority = Priority.fromValue(1);
        expect(priority, Priority.low);
        expect(priority.value, 1);
        expect(priority.label, 'Low');
      });

      test('should return medium priority for invalid value (default)', () {
        final priority = Priority.fromValue(99);
        expect(priority, Priority.medium);
      });

      test('should return medium priority for negative value', () {
        final priority = Priority.fromValue(-1);
        expect(priority, Priority.medium);
      });

      test('should return medium priority for zero', () {
        final priority = Priority.fromValue(0);
        expect(priority, Priority.medium);
      });

      test('should handle multiple invalid values', () {
        expect(Priority.fromValue(4), Priority.medium);
        expect(Priority.fromValue(100), Priority.medium);
        expect(Priority.fromValue(-999), Priority.medium);
      });
    });

    group('color properties', () {
      test('high priority should have red color', () {
        expect(Priority.high.color.value, 0xFFEF4444);
        expect(Priority.high.color.red, 0xEF);
        expect(Priority.high.color.green, 0x44);
        expect(Priority.high.color.blue, 0x44);
      });

      test('medium priority should have amber color', () {
        expect(Priority.medium.color.value, 0xFFF59E0B);
        expect(Priority.medium.color.red, 0xF5);
        expect(Priority.medium.color.green, 0x9E);
        expect(Priority.medium.color.blue, 0x0B);
      });

      test('low priority should have green color', () {
        expect(Priority.low.color.value, 0xFF22C55E);
        expect(Priority.low.color.red, 0x22);
        expect(Priority.low.color.green, 0xC5);
        expect(Priority.low.color.blue, 0x5E);
      });

      test('all colors should be fully opaque', () {
        expect(Priority.high.color.alpha, 0xFF);
        expect(Priority.medium.color.alpha, 0xFF);
        expect(Priority.low.color.alpha, 0xFF);
      });
    });

    group('enum equality', () {
      test('same priority values should be equal', () {
        expect(Priority.high, Priority.high);
        expect(Priority.medium, Priority.medium);
        expect(Priority.low, Priority.low);
      });

      test('different priority values should not be equal', () {
        expect(Priority.high, isNot(Priority.medium));
        expect(Priority.high, isNot(Priority.low));
        expect(Priority.medium, isNot(Priority.low));
      });

      test('fromValue should return equal enum for same value', () {
        final priority1 = Priority.fromValue(3);
        final priority2 = Priority.fromValue(3);
        expect(priority1, priority2);
        expect(priority1, Priority.high);
      });
    });

    group('enum name', () {
      test('should have correct name property', () {
        expect(Priority.high.name, 'high');
        expect(Priority.medium.name, 'medium');
        expect(Priority.low.name, 'low');
      });
    });

    group('enum index', () {
      test('should have correct index property', () {
        expect(Priority.high.index, 0);
        expect(Priority.medium.index, 1);
        expect(Priority.low.index, 2);
      });
    });

    group('value ordering', () {
      test('high should have highest value', () {
        expect(Priority.high.value > Priority.medium.value, true);
        expect(Priority.high.value > Priority.low.value, true);
      });

      test('medium should have middle value', () {
        expect(Priority.medium.value > Priority.low.value, true);
        expect(Priority.medium.value < Priority.high.value, true);
      });

      test('low should have lowest value', () {
        expect(Priority.low.value < Priority.medium.value, true);
        expect(Priority.low.value < Priority.high.value, true);
      });

      test('values should be sequential', () {
        expect(Priority.low.value, 1);
        expect(Priority.medium.value, 2);
        expect(Priority.high.value, 3);
        expect(Priority.high.value - Priority.medium.value, 1);
        expect(Priority.medium.value - Priority.low.value, 1);
      });
    });

    group('comprehensive fromValue tests', () {
      test('should correctly map all valid values', () {
        for (final priority in Priority.values) {
          final result = Priority.fromValue(priority.value);
          expect(result, priority);
          expect(result.value, priority.value);
          expect(result.label, priority.label);
          expect(result.color, priority.color);
        }
      });

      test('should handle boundary values', () {
        expect(Priority.fromValue(1), Priority.low);
        expect(Priority.fromValue(3), Priority.high);
      });

      test('should default to medium for all out-of-range values', () {
        final testValues = [-1000, -1, 0, 4, 5, 100, 999];
        for (final value in testValues) {
          expect(Priority.fromValue(value), Priority.medium,
              reason: 'Value $value should default to medium');
        }
      });
    });
  });
}
