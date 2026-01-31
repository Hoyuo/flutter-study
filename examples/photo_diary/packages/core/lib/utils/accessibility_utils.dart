import 'package:flutter/material.dart';

/// 접근성 유틸리티 클래스
///
/// WCAG(Web Content Accessibility Guidelines) 기준에 따라
/// 색상 대비, 터치 타겟 크기 등을 검증하는 유틸리티를 제공합니다.
class AccessibilityUtils {
  // coverage:ignore-start
  AccessibilityUtils._();
  // coverage:ignore-end

  /// WCAG AA 기준 색상 대비 확인 (최소 4.5:1)
  ///
  /// 일반 텍스트에 대한 최소 대비 비율을 검증합니다.
  /// - [foreground]: 전경색 (텍스트 색상)
  /// - [background]: 배경색
  /// - Returns: AA 기준 충족 여부
  static bool meetsAAContrast(Color foreground, Color background) {
    final ratio = _calculateContrastRatio(foreground, background);
    return ratio >= 4.5;
  }

  /// WCAG AAA 기준 색상 대비 확인 (최소 7:1)
  ///
  /// 강화된 접근성 기준으로, 더 높은 대비 비율을 요구합니다.
  /// - [foreground]: 전경색 (텍스트 색상)
  /// - [background]: 배경색
  /// - Returns: AAA 기준 충족 여부
  static bool meetsAAAContrast(Color foreground, Color background) {
    final ratio = _calculateContrastRatio(foreground, background);
    return ratio >= 7;
  }

  /// 대비 비율 계산
  ///
  /// WCAG 2.1 명도 대비 비율 공식을 사용하여 계산합니다.
  /// - [foreground]: 전경색
  /// - [background]: 배경색
  /// - Returns: 대비 비율 (1:1 ~ 21:1)
  static double _calculateContrastRatio(Color foreground, Color background) {
    final l1 = foreground.computeLuminance();
    final l2 = background.computeLuminance();
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// 최소 터치 타겟 크기 (48x48 dp)
  ///
  /// Material Design 및 iOS Human Interface Guidelines에서
  /// 권장하는 최소 터치 가능 영역 크기입니다.
  static const double minTouchTargetSize = 48;

  /// 터치 타겟 크기가 충분한지 확인
  ///
  /// - [size]: 확인할 위젯의 크기
  /// - Returns: 최소 크기 기준 충족 여부
  static bool isTouchTargetSufficient(Size size) {
    return size.width >= minTouchTargetSize &&
        size.height >= minTouchTargetSize;
  }
}
