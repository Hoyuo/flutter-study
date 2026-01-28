import 'package:core/utils/accessibility_utils.dart';
import 'package:flutter/material.dart';

/// 접근성이 적용된 버튼 위젯
///
/// 다음 기능을 자동으로 제공합니다:
/// - Semantics 레이블 자동 적용
/// - 최소 터치 타겟 크기 보장 (48x48 dp)
/// - 스크린 리더 지원
/// - 버튼 활성화/비활성화 상태 명시
class AccessibleButton extends StatelessWidget {
  /// 버튼 클릭 핸들러
  ///
  /// null이면 버튼이 비활성화됩니다.
  final VoidCallback? onPressed;

  /// 버튼 내부 콘텐츠
  final Widget child;

  /// 스크린 리더용 레이블
  ///
  /// 시각적으로 표시되는 텍스트와 다를 수 있습니다.
  /// 예: "저장" 버튼 → "일기 저장"
  final String semanticLabel;

  /// 스크린 리더용 힌트 (선택사항)
  ///
  /// 버튼의 동작을 설명하는 추가 정보를 제공합니다.
  /// 예: "탭하여 새 일기를 저장합니다"
  final String? semanticHint;

  /// Semantics를 제외할지 여부
  ///
  /// true이면 child의 자체 Semantics만 사용됩니다.
  final bool excludeSemantics;

  const AccessibleButton({
    required this.onPressed,
    required this.child,
    required this.semanticLabel,
    super.key,
    this.semanticHint,
    this.excludeSemantics = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      hint: semanticHint,
      excludeSemantics: excludeSemantics,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: AccessibilityUtils.minTouchTargetSize,
          minHeight: AccessibilityUtils.minTouchTargetSize,
        ),
        child: InkWell(
          onTap: onPressed,
          child: child,
        ),
      ),
    );
  }
}
