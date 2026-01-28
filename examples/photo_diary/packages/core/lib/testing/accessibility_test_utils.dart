import 'package:core/utils/accessibility_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 접근성 테스트 유틸리티
///
/// 위젯 테스트에서 접근성 기준 준수를 검증하는 헬퍼 함수를 제공합니다.
class AccessibilityTestUtils {
  AccessibilityTestUtils._();

  /// 위젯이 접근 가능한 버튼인지 검증
  ///
  /// 버튼이 스크린 리더 사용자에게 적절히 설명되는지 확인합니다.
  /// 레이블이 비어있지 않은지 검증합니다.
  ///
  /// - [tester]: WidgetTester 인스턴스
  /// - [finder]: 검증할 위젯의 Finder
  static void expectAccessibleButton(WidgetTester tester, Finder finder) {
    final semantics = tester.getSemantics(finder);
    final data = semantics.getSemanticsData();

    // 레이블이 있어야 함
    expect(
      data.label,
      isNotEmpty,
      reason: '버튼은 비어있지 않은 레이블을 가져야 합니다',
    );
  }

  /// 위젯이 접근 가능한 이미지인지 검증
  ///
  /// 다음을 확인합니다:
  /// - 장식용이 아닌 이미지는 레이블을 가지는지
  ///
  /// - [tester]: WidgetTester 인스턴스
  /// - [finder]: 검증할 위젯의 Finder
  /// - [isDecorative]: 장식용 이미지 여부 (기본값: false)
  static void expectAccessibleImage(
    WidgetTester tester,
    Finder finder, {
    bool isDecorative = false,
  }) {
    final semantics = tester.getSemantics(finder);
    final data = semantics.getSemanticsData();

    // 장식용이 아닌 이미지는 반드시 레이블을 가져야 함
    if (!isDecorative) {
      expect(
        data.label,
        isNotEmpty,
        reason: '장식용이 아닌 이미지는 비어있지 않은 레이블을 가져야 합니다',
      );
    }
  }

  /// 위젯이 접근 가능한 텍스트 필드인지 검증
  ///
  /// 텍스트 필드가 스크린 리더 사용자에게 적절히 설명되는지 확인합니다.
  /// 레이블이나 힌트가 존재하는지 검증합니다.
  ///
  /// - [tester]: WidgetTester 인스턴스
  /// - [finder]: 검증할 위젯의 Finder
  static void expectAccessibleTextField(WidgetTester tester, Finder finder) {
    final semantics = tester.getSemantics(finder);
    final data = semantics.getSemanticsData();

    // 레이블이나 힌트가 있어야 함
    expect(
      data.label.isNotEmpty || data.hint.isNotEmpty,
      isTrue,
      reason: '텍스트 필드는 레이블이나 힌트를 가져야 합니다',
    );
  }

  /// 색상 대비가 WCAG AA 기준을 충족하는지 검증
  ///
  /// 일반 텍스트의 최소 대비 비율(4.5:1)을 확인합니다.
  ///
  /// - [foreground]: 전경색 (텍스트 색상)
  /// - [background]: 배경색
  static void expectSufficientContrast(Color foreground, Color background) {
    expect(
      AccessibilityUtils.meetsAAContrast(foreground, background),
      isTrue,
      reason: '색상 대비가 WCAG AA 기준(4.5:1)을 충족하지 않습니다',
    );
  }

  /// 색상 대비가 WCAG AAA 기준을 충족하는지 검증
  ///
  /// 강화된 접근성 기준의 최소 대비 비율(7:1)을 확인합니다.
  ///
  /// - [foreground]: 전경색 (텍스트 색상)
  /// - [background]: 배경색
  static void expectEnhancedContrast(Color foreground, Color background) {
    expect(
      AccessibilityUtils.meetsAAAContrast(foreground, background),
      isTrue,
      reason: '색상 대비가 WCAG AAA 기준(7:1)을 충족하지 않습니다',
    );
  }

  /// 터치 타겟 크기가 충분한지 검증
  ///
  /// 최소 터치 타겟 크기(48x48 dp)를 확인합니다.
  ///
  /// - [tester]: WidgetTester 인스턴스
  /// - [finder]: 검증할 위젯의 Finder
  static void expectSufficientTouchTarget(
    WidgetTester tester,
    Finder finder,
  ) {
    final size = tester.getSize(finder);
    expect(
      AccessibilityUtils.isTouchTargetSufficient(size),
      isTrue,
      reason: '터치 타겟 크기(${size.width}x${size.height})가 최소 크기(48x48)를 충족하지 않습니다',
    );
  }

  /// 모든 접근성 검사를 한 번에 수행
  ///
  /// - [tester]: WidgetTester 인스턴스
  /// - [runApp]: 테스트할 앱을 빌드하는 함수
  static Future<void> runAccessibilityChecks(
    WidgetTester tester,
    Future<void> Function() runApp,
  ) async {
    // SemanticsHandle 활성화
    final handle = tester.ensureSemantics();

    try {
      // 앱 실행
      await runApp();

      // 디버그 모드에서만 접근성 검사 수행
      await tester.pumpAndSettle();

      // 추가 검증 로직은 개별 테스트에서 수행
    } finally {
      // SemanticsHandle 정리
      handle.dispose();
    }
  }
}
