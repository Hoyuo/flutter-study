import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings/presentation/widgets/theme_selector_dialog.dart';

void main() {
  group('ThemeSelectorDialog', () {
    Widget createTestWidget({required ThemeMode currentThemeMode}) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await ThemeSelectorDialog.show(
                  context,
                  currentThemeMode: currentThemeMode,
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );
    }

    testWidgets('다이얼로그가 올바른 제목으로 표시된다', (tester) async {
      await tester.pumpWidget(
        createTestWidget(currentThemeMode: ThemeMode.system),
      );
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('테마 선택'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('모든 테마 모드가 표시된다', (tester) async {
      await tester.pumpWidget(
        createTestWidget(currentThemeMode: ThemeMode.system),
      );
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // 라이트
      expect(find.text('라이트'), findsOneWidget);
      expect(find.text('밝은 테마'), findsOneWidget);

      // 다크
      expect(find.text('다크'), findsOneWidget);
      expect(find.text('어두운 테마'), findsOneWidget);

      // 시스템
      expect(find.text('시스템'), findsOneWidget);
      expect(find.text('기기 설정 따르기'), findsOneWidget);
    });

    testWidgets('현재 테마가 미리 선택되어 있다', (tester) async {
      await tester.pumpWidget(
        createTestWidget(currentThemeMode: ThemeMode.dark),
      );
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // dark가 선택된 RadioListTile 찾기
      final radioButtons = tester.widgetList<RadioListTile<ThemeMode>>(
        find.byType(RadioListTile<ThemeMode>),
      );

      final selectedRadio = radioButtons.firstWhere(
        (radio) => radio.value == ThemeMode.dark,
      );
      expect(selectedRadio.groupValue, ThemeMode.dark);
    });

    testWidgets('라이트 테마 선택 시 다이얼로그가 닫히고 ThemeMode.light를 반환한다',
        (tester) async {
      ThemeMode? selectedTheme;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedTheme = await ThemeSelectorDialog.show(
                    context,
                    currentThemeMode: ThemeMode.system,
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

      // 라이트 테마 선택
      await tester.tap(find.text('라이트'));
      await tester.pumpAndSettle();

      // 다이얼로그가 닫혔는지 확인
      expect(find.byType(AlertDialog), findsNothing);

      // ThemeMode가 반환되었는지 확인
      expect(selectedTheme, ThemeMode.light);
    });

    testWidgets('다크 테마 선택 시 다이얼로그가 닫히고 ThemeMode.dark를 반환한다',
        (tester) async {
      ThemeMode? selectedTheme;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedTheme = await ThemeSelectorDialog.show(
                    context,
                    currentThemeMode: ThemeMode.system,
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

      // 다크 테마 선택
      await tester.tap(find.text('다크'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(selectedTheme, ThemeMode.dark);
    });

    testWidgets('시스템 테마 선택 시 다이얼로그가 닫히고 ThemeMode.system을 반환한다',
        (tester) async {
      ThemeMode? selectedTheme;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedTheme = await ThemeSelectorDialog.show(
                    context,
                    currentThemeMode: ThemeMode.light,
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

      // 시스템 테마 선택
      await tester.tap(find.text('시스템'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(selectedTheme, ThemeMode.system);
    });

    testWidgets('취소 버튼 탭 시 다이얼로그가 닫히고 null을 반환한다', (tester) async {
      ThemeMode? selectedTheme;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedTheme = await ThemeSelectorDialog.show(
                    context,
                    currentThemeMode: ThemeMode.system,
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
      expect(selectedTheme, isNull);
    });

    testWidgets('각 RadioListTile이 올바른 값으로 표시된다', (tester) async {
      await tester.pumpWidget(
        createTestWidget(currentThemeMode: ThemeMode.system),
      );
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // RadioListTile 확인
      expect(find.byType(RadioListTile<ThemeMode>), findsNWidgets(3));

      final radioButtons = tester.widgetList<RadioListTile<ThemeMode>>(
        find.byType(RadioListTile<ThemeMode>),
      );

      final values = radioButtons.map((radio) => radio.value).toList();
      expect(
        values,
        containsAll([ThemeMode.light, ThemeMode.dark, ThemeMode.system]),
      );
    });
  });
}
