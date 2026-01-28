import 'package:flutter/material.dart';

/// 테마 선택 다이얼로그
class ThemeSelectorDialog extends StatelessWidget {
  /// 현재 테마 모드
  final ThemeMode currentThemeMode;

  const ThemeSelectorDialog({
    super.key,
    required this.currentThemeMode,
  });

  /// 다이얼로그 표시
  static Future<ThemeMode?> show(
    BuildContext context, {
    required ThemeMode currentThemeMode,
  }) {
    return showDialog<ThemeMode>(
      context: context,
      builder: (context) => ThemeSelectorDialog(
        currentThemeMode: currentThemeMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('테마 선택'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('라이트'),
            subtitle: const Text('밝은 테마'),
            value: ThemeMode.light,
            groupValue: currentThemeMode,
            onChanged: (value) {
              if (value != null) {
                Navigator.of(context).pop(value);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('다크'),
            subtitle: const Text('어두운 테마'),
            value: ThemeMode.dark,
            groupValue: currentThemeMode,
            onChanged: (value) {
              if (value != null) {
                Navigator.of(context).pop(value);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('시스템'),
            subtitle: const Text('기기 설정 따르기'),
            value: ThemeMode.system,
            groupValue: currentThemeMode,
            onChanged: (value) {
              if (value != null) {
                Navigator.of(context).pop(value);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
      ],
    );
  }
}
