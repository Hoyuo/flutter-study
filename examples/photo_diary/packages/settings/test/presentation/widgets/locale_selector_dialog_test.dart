import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings/presentation/widgets/locale_selector_dialog.dart';

void main() {
  group('LocaleSelectorDialog', () {
    Widget createTestWidget({required String currentLanguageCode}) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await LocaleSelectorDialog.show(
                  context,
                  currentLanguageCode: currentLanguageCode,
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );
    }

    testWidgets('다이얼로그가 올바른 제목으로 표시된다', (tester) async {
      await tester.pumpWidget(createTestWidget(currentLanguageCode: 'ko'));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('언어 선택'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('지원하는 모든 언어가 표시된다', (tester) async {
      await tester.pumpWidget(createTestWidget(currentLanguageCode: 'ko'));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // 한국어
      expect(find.text('한국어'), findsOneWidget);
      expect(find.text('Korean'), findsOneWidget);

      // 일본어
      expect(find.text('日本語'), findsOneWidget);
      expect(find.text('Japanese'), findsOneWidget);

      // 중국어
      expect(find.text('繁體中文'), findsOneWidget);
      expect(find.text('Traditional Chinese'), findsOneWidget);
    });

    testWidgets('현재 언어가 미리 선택되어 있다', (tester) async {
      await tester.pumpWidget(createTestWidget(currentLanguageCode: 'ko'));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // ko가 선택된 RadioListTile 찾기
      final radioButtons = tester.widgetList<RadioListTile<String>>(
        find.byType(RadioListTile<String>),
      );

      final selectedRadio = radioButtons.firstWhere(
        (radio) => radio.value == 'ko',
      );
      expect(selectedRadio.groupValue, 'ko');
    });

    testWidgets('언어 선택 시 다이얼로그가 닫히고 Locale을 반환한다', (tester) async {
      Locale? selectedLocale;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedLocale = await LocaleSelectorDialog.show(
                    context,
                    currentLanguageCode: 'ko',
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // 일본어 선택
      await tester.tap(find.text('日本語'));
      await tester.pumpAndSettle();

      // 다이얼로그가 닫혔는지 확인
      expect(find.byType(AlertDialog), findsNothing);

      // Locale이 반환되었는지 확인
      expect(selectedLocale, isNotNull);
      expect(selectedLocale?.languageCode, 'ja');
    });

    testWidgets('취소 버튼 탭 시 다이얼로그가 닫히고 null을 반환한다', (tester) async {
      Locale? selectedLocale;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedLocale = await LocaleSelectorDialog.show(
                    context,
                    currentLanguageCode: 'ko',
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // 취소 버튼 탭
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      // 다이얼로그가 닫혔는지 확인
      expect(find.byType(AlertDialog), findsNothing);

      // null이 반환되었는지 확인
      expect(selectedLocale, isNull);
    });

    testWidgets('각 RadioListTile이 올바른 값으로 표시된다', (tester) async {
      await tester.pumpWidget(createTestWidget(currentLanguageCode: 'ko'));
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // RadioListTile 확인
      expect(find.byType(RadioListTile<String>), findsNWidgets(3));

      final radioButtons = tester.widgetList<RadioListTile<String>>(
        find.byType(RadioListTile<String>),
      );

      final values = radioButtons.map((radio) => radio.value).toList();
      expect(values, containsAll(['ko', 'ja', 'zh']));
    });

    testWidgets('중국어 선택이 작동한다', (tester) async {
      Locale? selectedLocale;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedLocale = await LocaleSelectorDialog.show(
                    context,
                    currentLanguageCode: 'ko',
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // 중국어 선택
      await tester.tap(find.text('繁體中文'));
      await tester.pumpAndSettle();

      expect(selectedLocale?.languageCode, 'zh');
    });
  });
}
