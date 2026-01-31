import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings/presentation/widgets/settings_section.dart';
import 'package:settings/presentation/widgets/settings_tile.dart';

void main() {
  group('SettingsSection', () {
    Widget createTestWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: child,
        ),
      );
    }

    testWidgets('제목과 자식 위젯이 표시된다', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SettingsSection(
            title: 'Test Section',
            children: [
              SettingsTile(title: 'Item 1'),
              SettingsTile(title: 'Item 2'),
            ],
          ),
        ),
      );

      // 제목 확인
      expect(find.text('Test Section'), findsOneWidget);

      // 자식 위젯 확인
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);

      // Card 확인
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('제목 없이 자식 위젯만 표시된다', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SettingsSection(
            children: [
              SettingsTile(title: 'Item 1'),
              SettingsTile(title: 'Item 2'),
            ],
          ),
        ),
      );

      // 자식 위젯 확인
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);

      // Card는 여전히 표시
      expect(find.byType(Card), findsOneWidget);

      // Padding이 제목용으로 추가되지 않았는지 확인
      final column = tester.widget<Column>(find.byType(Column).first);
      // title이 null이면 자식이 1개 (Card만)
      expect(column.children.length, 1);
    });

    testWidgets('빈 자식 리스트로 표시된다', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SettingsSection(
            title: 'Empty Section',
            children: [],
          ),
        ),
      );

      // 제목 확인
      expect(find.text('Empty Section'), findsOneWidget);

      // Card 확인
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('제목이 primary 색상으로 표시된다', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SettingsSection(
            title: 'Colored Title',
            children: [SettingsTile(title: 'Item')],
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Colored Title'));
      final theme = Theme.of(tester.element(find.byType(Scaffold)));

      expect(textWidget.style?.color, theme.colorScheme.primary);
      expect(textWidget.style?.fontWeight, FontWeight.bold);
    });
  });
}
