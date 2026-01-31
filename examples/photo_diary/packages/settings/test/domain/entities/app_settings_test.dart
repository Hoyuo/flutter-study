import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings/domain/entities/entities.dart';

void main() {
  group('TimeOfDayConverter', () {
    const converter = TimeOfDayConverter();

    test('fromJson - null 값 처리', () {
      expect(converter.fromJson(null), isNull);
    });

    test('fromJson - 정상 변환', () {
      final json = {'hour': 14, 'minute': 30};
      final result = converter.fromJson(json);
      expect(result?.hour, 14);
      expect(result?.minute, 30);
    });

    test('toJson - null 값 처리', () {
      expect(converter.toJson(null), isNull);
    });

    test('toJson - 정상 변환', () {
      const timeOfDay = TimeOfDay(hour: 14, minute: 30);
      final result = converter.toJson(timeOfDay);
      expect(result, {'hour': 14, 'minute': 30});
    });
  });
}
