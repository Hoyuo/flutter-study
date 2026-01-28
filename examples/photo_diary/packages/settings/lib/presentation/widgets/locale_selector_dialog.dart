import 'package:flutter/material.dart';

/// 언어 선택 다이얼로그
class LocaleSelectorDialog extends StatelessWidget {
  /// 현재 언어 코드
  final String currentLanguageCode;

  /// 지원하는 언어 목록
  static const supportedLocales = {
    'ko': {'name': '한국어', 'subtitle': 'Korean'},
    'ja': {'name': '日本語', 'subtitle': 'Japanese'},
    'zh': {'name': '繁體中文', 'subtitle': 'Traditional Chinese'},
  };

  const LocaleSelectorDialog({
    super.key,
    required this.currentLanguageCode,
  });

  /// 다이얼로그 표시
  static Future<Locale?> show(
    BuildContext context, {
    required String currentLanguageCode,
  }) {
    return showDialog<Locale>(
      context: context,
      builder: (context) => LocaleSelectorDialog(
        currentLanguageCode: currentLanguageCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('언어 선택'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: supportedLocales.entries.map((entry) {
          final languageCode = entry.key;
          final languageInfo = entry.value;

          return RadioListTile<String>(
            title: Text(languageInfo['name']!),
            subtitle: Text(languageInfo['subtitle']!),
            value: languageCode,
            groupValue: currentLanguageCode,
            onChanged: (value) {
              if (value != null) {
                Navigator.of(context).pop(Locale(value));
              }
            },
          );
        }).toList(),
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
