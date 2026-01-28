import 'dart:math' show pow;
import 'dart:ui';

/// 접근성 관련 유틸리티 함수 모음
///
/// WCAG(Web Content Accessibility Guidelines) 기준을 따릅니다.
class AccessibilityUtils {
  AccessibilityUtils._();

  /// WCAG AA 기준 색상 대비율 체크 (최소 4.5:1)
  ///
  /// 일반 텍스트에 대한 최소 대비율입니다.
  /// - 작은 텍스트(18pt 미만): 4.5:1
  /// - 큰 텍스트(18pt 이상 또는 14pt bold): 3:1
  ///
  /// Example:
  /// ```dart
  /// final hasGoodContrast = AccessibilityUtils.meetsAAContrast(
  ///   Colors.white,
  ///   Colors.blue,
  /// );
  /// ```
  static bool meetsAAContrast(Color foreground, Color background) {
    final contrastRatio = calculateContrastRatio(foreground, background);
    return contrastRatio >= 4.5;
  }

  /// WCAG AAA 기준 색상 대비율 체크 (최소 7:1)
  ///
  /// 더 높은 수준의 접근성을 위한 대비율입니다.
  /// - 작은 텍스트(18pt 미만): 7:1
  /// - 큰 텍스트(18pt 이상 또는 14pt bold): 4.5:1
  ///
  /// Example:
  /// ```dart
  /// final hasExcellentContrast = AccessibilityUtils.meetsAAAContrast(
  ///   Colors.white,
  ///   Colors.black,
  /// );
  /// ```
  static bool meetsAAAContrast(Color foreground, Color background) {
    final contrastRatio = calculateContrastRatio(foreground, background);
    return contrastRatio >= 7.0;
  }

  /// 큰 텍스트에 대한 WCAG AA 기준 체크 (최소 3:1)
  ///
  /// 18pt 이상 또는 14pt bold 텍스트에 적용됩니다.
  static bool meetsAAContrastLargeText(Color foreground, Color background) {
    final contrastRatio = calculateContrastRatio(foreground, background);
    return contrastRatio >= 3.0;
  }

  /// 큰 텍스트에 대한 WCAG AAA 기준 체크 (최소 4.5:1)
  ///
  /// 18pt 이상 또는 14pt bold 텍스트에 적용됩니다.
  static bool meetsAAAContrastLargeText(Color foreground, Color background) {
    final contrastRatio = calculateContrastRatio(foreground, background);
    return contrastRatio >= 4.5;
  }

  /// 두 색상 간의 대비율 계산
  ///
  /// WCAG 2.1 기준을 따릅니다.
  /// 반환값 범위: 1:1 (최소) ~ 21:1 (최대)
  ///
  /// Example:
  /// ```dart
  /// final ratio = AccessibilityUtils.calculateContrastRatio(
  ///   Colors.white,  // #FFFFFF
  ///   Colors.black,  // #000000
  /// );
  /// // ratio = 21.0 (최대 대비)
  /// ```
  static double calculateContrastRatio(Color color1, Color color2) {
    final luminance1 = _relativeLuminance(color1);
    final luminance2 = _relativeLuminance(color2);

    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// 색상의 상대 휘도(Relative Luminance) 계산
  ///
  /// WCAG 2.1 기준을 따릅니다.
  /// 반환값 범위: 0.0 (검정) ~ 1.0 (흰색)
  ///
  /// 공식: L = 0.2126 * R + 0.7152 * G + 0.0722 * B
  /// (R, G, B는 sRGB 색 공간에서 조정된 값)
  static double _relativeLuminance(Color color) {
    final r = _adjustChannel(color.red / 255.0);
    final g = _adjustChannel(color.green / 255.0);
    final b = _adjustChannel(color.blue / 255.0);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// sRGB 색 공간에서 채널 값 조정
  ///
  /// WCAG 2.1 공식:
  /// - if (c <= 0.03928) then c / 12.92
  /// - else ((c + 0.055) / 1.055) ^ 2.4
  static double _adjustChannel(double channel) {
    if (channel <= 0.03928) {
      return channel / 12.92;
    }
    return pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  /// 대비율 등급 반환
  ///
  /// Returns:
  /// - 'AAA': WCAG AAA 기준 충족 (7:1 이상)
  /// - 'AA': WCAG AA 기준 충족 (4.5:1 이상)
  /// - 'AA Large': 큰 텍스트 WCAG AA 기준 충족 (3:1 이상)
  /// - 'Fail': 모든 기준 미달
  ///
  /// Example:
  /// ```dart
  /// final grade = AccessibilityUtils.getContrastGrade(
  ///   Colors.white,
  ///   Colors.blue,
  /// );
  /// print('대비율 등급: $grade');
  /// ```
  static String getContrastGrade(Color foreground, Color background) {
    final ratio = calculateContrastRatio(foreground, background);

    if (ratio >= 7.0) {
      return 'AAA';
    } else if (ratio >= 4.5) {
      return 'AA';
    } else if (ratio >= 3.0) {
      return 'AA Large';
    } else {
      return 'Fail';
    }
  }

  /// 색상 대비율을 사람이 읽기 쉬운 형식으로 반환
  ///
  /// Example:
  /// ```dart
  /// final description = AccessibilityUtils.getContrastDescription(
  ///   Colors.white,
  ///   Colors.black,
  /// );
  /// print(description); // "21.0:1 (AAA) - 최상의 대비"
  /// ```
  static String getContrastDescription(Color foreground, Color background) {
    final ratio = calculateContrastRatio(foreground, background);
    final grade = getContrastGrade(foreground, background);

    String description;
    if (ratio >= 7.0) {
      description = '최상의 대비';
    } else if (ratio >= 4.5) {
      description = '좋은 대비';
    } else if (ratio >= 3.0) {
      description = '큰 텍스트에만 적합';
    } else {
      description = '대비 불충분 - 개선 필요';
    }

    return '${ratio.toStringAsFixed(1)}:1 ($grade) - $description';
  }

  /// 주어진 배경색에 적합한 전경색(텍스트 색상) 반환
  ///
  /// 배경색의 밝기에 따라 검정 또는 흰색을 반환합니다.
  ///
  /// Example:
  /// ```dart
  /// final textColor = AccessibilityUtils.getContrastingTextColor(
  ///   Colors.blue,
  /// );
  /// // Returns: Colors.white (파란색 배경에는 흰색 텍스트)
  /// ```
  static Color getContrastingTextColor(Color backgroundColor) {
    final luminance = _relativeLuminance(backgroundColor);
    // 휘도가 0.5보다 크면 어두운 배경이므로 흰색 텍스트 사용
    return luminance > 0.5 ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  }

  /// 색상이 밝은지 어두운지 판단
  ///
  /// Returns: true if 밝은 색상, false if 어두운 색상
  static bool isLightColor(Color color) {
    final luminance = _relativeLuminance(color);
    return luminance > 0.5;
  }
}
