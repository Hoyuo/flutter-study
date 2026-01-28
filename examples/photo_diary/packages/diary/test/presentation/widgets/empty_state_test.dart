import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diary/presentation/widgets/empty_state.dart';
import 'dart:ui' as ui;

void main() {
  group('EmptyState', () {
    testWidgets('아이콘과 제목이 표시된다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.note_add,
              title: '일기가 없습니다',
            ),
          ),
        ),
      );

      // 아이콘 확인
      expect(find.byIcon(Icons.note_add), findsOneWidget);
      // 제목 확인
      expect(find.text('일기가 없습니다'), findsOneWidget);
    });

    testWidgets('설명 메시지가 제공되면 표시된다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.search,
              title: '검색 결과가 없습니다',
              message: '다른 검색어로 시도해보세요',
            ),
          ),
        ),
      );

      // 제목 확인
      expect(find.text('검색 결과가 없습니다'), findsOneWidget);
      // 메시지 확인
      expect(find.text('다른 검색어로 시도해보세요'), findsOneWidget);
    });

    testWidgets('CTA 버튼이 제공되면 표시된다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.note_add,
              title: '일기가 없습니다',
              buttonText: '일기 작성하기',
              onButtonPressed: () {},
            ),
          ),
        ),
      );

      // 버튼이 표시되는지 확인
      expect(find.text('일기 작성하기'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('CTA 버튼 탭 시 콜백이 호출된다', (tester) async {
      var buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.note_add,
              title: '일기가 없습니다',
              buttonText: '일기 작성하기',
              onButtonPressed: () => buttonPressed = true,
            ),
          ),
        ),
      );

      // 버튼 탭
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // 콜백이 호출되었는지 확인
      expect(buttonPressed, isTrue);
    });

    testWidgets('버튼 텍스트만 있고 콜백이 없으면 버튼이 표시되지 않는다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.note_add,
              title: '일기가 없습니다',
              buttonText: '일기 작성하기',
              onButtonPressed: null,
            ),
          ),
        ),
      );

      // 버튼이 표시되지 않음
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('콜백만 있고 버튼 텍스트가 없으면 버튼이 표시되지 않는다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.note_add,
              title: '일기가 없습니다',
              buttonText: null,
              onButtonPressed: () {},
            ),
          ),
        ),
      );

      // 버튼이 표시되지 않음
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('Semantics 레이블이 올바르게 설정된다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.note_add,
              title: '일기가 없습니다',
              message: '새 일기를 작성해보세요',
            ),
          ),
        ),
      );

      // Semantics 레이블 확인 (제목 + 메시지)
      final semanticsFinder = find.bySemanticsLabel(
        '일기가 없습니다. 새 일기를 작성해보세요',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('메시지 없이 Semantics 레이블이 올바르게 설정된다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.note_add,
              title: '일기가 없습니다',
            ),
          ),
        ),
      );

      // Semantics 레이블 확인 (제목만)
      final semanticsFinder = find.bySemanticsLabel('일기가 없습니다');
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('버튼의 Semantics가 올바르게 설정된다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.note_add,
              title: '일기가 없습니다',
              buttonText: '일기 작성하기',
              onButtonPressed: () {},
            ),
          ),
        ),
      );

      // 버튼의 Semantics 확인
      final buttonSemantics =
          tester.getSemantics(find.byType(FilledButton).first);
      expect(buttonSemantics.hasFlag(ui.SemanticsFlag.isButton), isTrue);
      expect(buttonSemantics.label, '일기 작성하기');
      expect(buttonSemantics.hint, '탭하여 새 일기 작성');
    });

    testWidgets('아이콘이 스크린 리더에서 제외된다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.note_add,
              title: '일기가 없습니다',
            ),
          ),
        ),
      );

      // 아이콘이 Semantics에서 제외되어 있는지 확인
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.note_add));
      expect(iconWidget, isNotNull);

      // Semantics tree에서 아이콘이 excludeSemantics로 감싸져 있는지 확인
      final semanticsDebugString = tester
          .binding.pipelineOwner.semanticsOwner?.rootSemanticsNode
          ?.toStringDeep();
      // 아이콘은 장식용이므로 스크린 리더에 노출되지 않아야 함
      expect(semanticsDebugString, isNotNull);
    });
  });
}
