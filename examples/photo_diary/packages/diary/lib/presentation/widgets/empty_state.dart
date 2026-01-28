import 'package:flutter/material.dart';

/// 빈 상태를 표시하는 위젯
///
/// 일기가 없거나 검색 결과가 없을 때 사용합니다.
class EmptyState extends StatelessWidget {
  /// 표시할 아이콘
  final IconData icon;

  /// 제목 메시지
  final String title;

  /// 설명 메시지 (선택사항)
  final String? message;

  /// CTA 버튼 텍스트 (선택사항)
  final String? buttonText;

  /// CTA 버튼 클릭 핸들러 (선택사항)
  final VoidCallback? onButtonPressed;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 아이콘과 텍스트를 하나의 Semantics 컨테이너로 묶음
            Semantics(
              label: '$title${message != null ? '. $message' : ''}',
              container: true,
              child: ExcludeSemantics(
                child: Column(
                  children: [
                    // 아이콘 (장식용이므로 스크린 리더에서 제외)
                    Icon(
                      icon,
                      size: 80,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(height: 24),

                    // 제목
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // 설명 메시지
                    if (message != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        message!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // CTA 버튼 (버튼은 Semantics에서 제외하지 않음)
            if (buttonText != null && onButtonPressed != null)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Semantics(
                  button: true,
                  enabled: true,
                  label: buttonText!,
                  hint: '탭하여 새 일기 작성',
                  child: ExcludeSemantics(
                    child: FilledButton(
                      onPressed: onButtonPressed,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add),
                          const SizedBox(width: 8),
                          Text(buttonText!),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
