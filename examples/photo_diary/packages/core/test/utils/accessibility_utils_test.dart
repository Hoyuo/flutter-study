import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/utils/accessibility_utils.dart';

void main() {
  group('AccessibilityUtils', () {
    group('meetsAAContrast', () {
      test('검은색과 흰색은 AA 기준을 충족한다', () {
        final result = AccessibilityUtils.meetsAAContrast(
          Colors.black,
          Colors.white,
        );
        expect(result, isTrue);
      });

      test('흰색과 검은색은 AA 기준을 충족한다', () {
        final result = AccessibilityUtils.meetsAAContrast(
          Colors.white,
          Colors.black,
        );
        expect(result, isTrue);
      });

      test('충분한 대비를 가진 색상은 AA 기준을 충족한다', () {
        // 진한 파란색과 흰색 (높은 대비)
        final result = AccessibilityUtils.meetsAAContrast(
          const Color(0xFF0000AA),
          Colors.white,
        );
        expect(result, isTrue);
      });

      test('낮은 대비를 가진 색상은 AA 기준을 충족하지 못한다', () {
        // 연한 회색과 흰색 (낮은 대비)
        final result = AccessibilityUtils.meetsAAContrast(
          const Color(0xFFCCCCCC),
          Colors.white,
        );
        expect(result, isFalse);
      });

      test('중간 대비 색상의 경계값을 정확히 판단한다', () {
        // 대비 비율 4.5:1에 가까운 색상들
        final result1 = AccessibilityUtils.meetsAAContrast(
          const Color(0xFF767676),
          Colors.white,
        );
        expect(result1, isTrue); // 4.54:1 정도

        final result2 = AccessibilityUtils.meetsAAContrast(
          const Color(0xFF888888),
          Colors.white,
        );
        expect(result2, isFalse); // 3.54:1 정도
      });

      test('동일한 색상은 AA 기준을 충족하지 못한다', () {
        final result = AccessibilityUtils.meetsAAContrast(
          Colors.blue,
          Colors.blue,
        );
        expect(result, isFalse);
      });

      test('알파 채널이 포함된 색상도 올바르게 처리한다', () {
        final result = AccessibilityUtils.meetsAAContrast(
          Colors.black.withOpacity(0.87),
          Colors.white,
        );
        expect(result, isTrue);
      });
    });

    group('meetsAAAContrast', () {
      test('검은색과 흰색은 AAA 기준을 충족한다', () {
        final result = AccessibilityUtils.meetsAAAContrast(
          Colors.black,
          Colors.white,
        );
        expect(result, isTrue);
      });

      test('흰색과 검은색은 AAA 기준을 충족한다', () {
        final result = AccessibilityUtils.meetsAAAContrast(
          Colors.white,
          Colors.black,
        );
        expect(result, isTrue);
      });

      test('중간 대비 색상은 AAA 기준을 충족하지 못한다', () {
        // AA는 통과하지만 AAA는 통과하지 못하는 색상
        final result = AccessibilityUtils.meetsAAAContrast(
          const Color(0xFF767676),
          Colors.white,
        );
        expect(result, isFalse); // 약 4.5:1 대비 (AA 통과, AAA 실패)
      });

      test('충분히 높은 대비를 가진 색상은 AAA 기준을 충족한다', () {
        final result = AccessibilityUtils.meetsAAAContrast(
          const Color(0xFF333333),
          Colors.white,
        );
        expect(result, isTrue); // 약 12:1 대비
      });

      test('AAA 기준의 경계값을 정확히 판단한다', () {
        // 대비 비율 7:1에 가까운 색상들
        final result1 = AccessibilityUtils.meetsAAAContrast(
          const Color(0xFF666666),
          Colors.white,
        );
        expect(result1, isFalse); // 5.7:1 정도 (AAA 실패)

        final result2 = AccessibilityUtils.meetsAAAContrast(
          const Color(0xFF555555),
          Colors.white,
        );
        expect(result2, isTrue); // 7.4:1 정도 (AAA 통과)
      });

      test('동일한 색상은 AAA 기준을 충족하지 못한다', () {
        final result = AccessibilityUtils.meetsAAAContrast(
          Colors.red,
          Colors.red,
        );
        expect(result, isFalse);
      });

      test('진한 파란색과 흰색은 AAA 기준을 충족한다', () {
        final result = AccessibilityUtils.meetsAAAContrast(
          const Color(0xFF000080),
          Colors.white,
        );
        expect(result, isTrue);
      });
    });

    group('isTouchTargetSufficient', () {
      test('최소 크기보다 큰 타겟은 충분하다고 판단한다', () {
        final result = AccessibilityUtils.isTouchTargetSufficient(
          const Size(50, 50),
        );
        expect(result, isTrue);
      });

      test('최소 크기와 정확히 같은 타겟은 충분하다고 판단한다', () {
        final result = AccessibilityUtils.isTouchTargetSufficient(
          const Size(48, 48),
        );
        expect(result, isTrue);
      });

      test('최소 크기보다 작은 타겟은 충분하지 않다고 판단한다', () {
        final result = AccessibilityUtils.isTouchTargetSufficient(
          const Size(40, 40),
        );
        expect(result, isFalse);
      });

      test('너비만 충분하지 않은 타겟은 충분하지 않다고 판단한다', () {
        final result = AccessibilityUtils.isTouchTargetSufficient(
          const Size(30, 50),
        );
        expect(result, isFalse);
      });

      test('높이만 충분하지 않은 타겟은 충분하지 않다고 판단한다', () {
        final result = AccessibilityUtils.isTouchTargetSufficient(
          const Size(50, 30),
        );
        expect(result, isFalse);
      });

      test('너비와 높이 모두 충분하지 않은 타겟은 충분하지 않다고 판단한다', () {
        final result = AccessibilityUtils.isTouchTargetSufficient(
          const Size(20, 20),
        );
        expect(result, isFalse);
      });

      test('매우 큰 타겟은 충분하다고 판단한다', () {
        final result = AccessibilityUtils.isTouchTargetSufficient(
          const Size(100, 100),
        );
        expect(result, isTrue);
      });

      test('긴 직사각형 타겟도 충분하면 충분하다고 판단한다', () {
        final result = AccessibilityUtils.isTouchTargetSufficient(
          const Size(200, 48),
        );
        expect(result, isTrue);
      });

      test('넓은 직사각형 타겟도 충분하면 충분하다고 판단한다', () {
        final result = AccessibilityUtils.isTouchTargetSufficient(
          const Size(48, 200),
        );
        expect(result, isTrue);
      });

      test('경계값 미만의 타겟은 충분하지 않다고 판단한다', () {
        final result = AccessibilityUtils.isTouchTargetSufficient(
          const Size(47.9, 47.9),
        );
        expect(result, isFalse);
      });
    });

    group('minTouchTargetSize', () {
      test('최소 터치 타겟 크기는 48이다', () {
        expect(AccessibilityUtils.minTouchTargetSize, equals(48.0));
      });
    });

    group('색상 대비 종합 테스트', () {
      test('Material Design 표준 색상들의 대비를 확인한다', () {
        // Primary color와 surface의 대비
        final primaryOnSurface = AccessibilityUtils.meetsAAContrast(
          const Color(0xFF6200EE),
          Colors.white,
        );
        expect(primaryOnSurface, isTrue);

        // Error color와 surface의 대비
        final errorOnSurface = AccessibilityUtils.meetsAAContrast(
          const Color(0xFFB00020),
          Colors.white,
        );
        expect(errorOnSurface, isTrue);
      });

      test('다양한 회색 음영의 대비를 확인한다', () {
        final shades = [
          Colors.grey.shade100,
          Colors.grey.shade300,
          Colors.grey.shade500,
          Colors.grey.shade700,
          Colors.grey.shade900,
        ];

        for (final shade in shades) {
          final onWhite = AccessibilityUtils.meetsAAContrast(shade, Colors.white);
          final onBlack = AccessibilityUtils.meetsAAContrast(shade, Colors.black);
          // 최소한 하나는 통과해야 함
          expect(onWhite || onBlack, isTrue);
        }
      });
    });

    group('터치 타겟 크기 종합 테스트', () {
      test('다양한 일반적인 버튼 크기를 검증한다', () {
        final commonSizes = [
          const Size(32, 32), // 작은 아이콘 버튼 - 실패
          const Size(40, 40), // 중간 아이콘 버튼 - 실패
          const Size(48, 48), // 최소 권장 크기 - 성공
          const Size(56, 56), // 표준 버튼 - 성공
          const Size(64, 64), // 큰 버튼 - 성공
        ];

        final results = commonSizes.map(
          AccessibilityUtils.isTouchTargetSufficient,
        ).toList();

        expect(results, equals([false, false, true, true, true]));
      });
    });
  });
}
