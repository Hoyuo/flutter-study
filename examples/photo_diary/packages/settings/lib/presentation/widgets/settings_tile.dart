import 'package:flutter/material.dart';

/// 설정 항목 타일
class SettingsTile extends StatelessWidget {
  /// 아이콘
  final IconData? icon;

  /// 제목
  final String title;

  /// 부제목
  final String? subtitle;

  /// 후행 위젯
  final Widget? trailing;

  /// 탭 핸들러
  final VoidCallback? onTap;

  /// 활성화 여부
  final bool enabled;

  const SettingsTile({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      enabled: enabled,
      leading: icon != null
          ? Icon(
              icon,
              color: enabled ? theme.colorScheme.primary : theme.disabledColor,
            )
          : null,
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: enabled ? null : theme.disabledColor,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: enabled
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.disabledColor,
              ),
            )
          : null,
      trailing: trailing,
      onTap: enabled ? onTap : null,
    );
  }
}
