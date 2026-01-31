import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings/presentation/widgets/settings_tile.dart';

void main() {
  group('SettingsTile', () {
    Widget createTestWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: child,
        ),
      );
    }

    testWidgets('활성화 상태에서 모든 속성이 표시된다', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        createTestWidget(
          SettingsTile(
            icon: Icons.settings,
            title: 'Test Title',
            subtitle: 'Test Subtitle',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => tapped = true,
            enabled: true,
          ),
        ),
      );

      // 모든 요소 확인
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      // 탭 이벤트 확인
      await tester.tap(find.byType(ListTile));
      expect(tapped, isTrue);
    });

    testWidgets('비활성화 상태에서 부제목이 표시된다', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SettingsTile(
            icon: Icons.settings,
            title: 'Disabled Title',
            subtitle: 'Disabled Subtitle',
            enabled: false,
          ),
        ),
      );

      // 요소 확인 (line 57 커버)
      expect(find.text('Disabled Title'), findsOneWidget);
      expect(find.text('Disabled Subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);

      // ListTile 확인
      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.enabled, isFalse);
    });

    testWidgets('비활성화 상태에서 탭 이벤트가 무시된다', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        createTestWidget(
          SettingsTile(
            title: 'Disabled',
            onTap: () => tapped = true,
            enabled: false,
          ),
        ),
      );

      // 탭 시도
      await tester.tap(find.byType(ListTile));

      // onTap이 호출되지 않음
      expect(tapped, isFalse);
    });

    testWidgets('아이콘 없이 표시된다', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SettingsTile(
            title: 'No Icon',
            subtitle: 'This has no icon',
          ),
        ),
      );

      expect(find.text('No Icon'), findsOneWidget);
      expect(find.text('This has no icon'), findsOneWidget);

      // ListTile의 leading이 null인지 확인
      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.leading, isNull);
    });

    testWidgets('부제목 없이 표시된다', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SettingsTile(
            icon: Icons.settings,
            title: 'No Subtitle',
          ),
        ),
      );

      expect(find.text('No Subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);

      // subtitle Text 위젯이 없는지 확인
      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.subtitle, isNull);
    });

    testWidgets('후행 위젯 없이 표시된다', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SettingsTile(
            icon: Icons.settings,
            title: 'No Trailing',
          ),
        ),
      );

      expect(find.text('No Trailing'), findsOneWidget);

      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.trailing, isNull);
    });

    testWidgets('활성화 상태에서 아이콘 색상이 primary이다', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SettingsTile(
            icon: Icons.settings,
            title: 'Enabled',
            enabled: true,
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.settings));
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(iconWidget.color, theme.colorScheme.primary);
    });

    testWidgets('비활성화 상태에서 아이콘 색상이 disabledColor이다', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SettingsTile(
            icon: Icons.settings,
            title: 'Disabled',
            enabled: false,
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.settings));
      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(iconWidget.color, theme.disabledColor);
    });
  });
}
