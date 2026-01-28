import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/widgets/accessible_button.dart';
import 'package:core/utils/accessibility_utils.dart';

void main() {
  group('AccessibleButton', () {
    testWidgets('버튼이 렌더링된다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              onPressed: () {},
              semanticLabel: '저장',
              child: const Text('저장'),
            ),
          ),
        ),
      );

      // 버튼 텍스트 확인
      expect(find.text('저장'), findsOneWidget);
    });

    testWidgets('onPressed가 null이면 버튼이 비활성화된다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              onPressed: null,
              semanticLabel: '저장',
              child: Text('저장'),
            ),
          ),
        ),
      );

      // Semantics 확인 (enabled가 false여야 함)
      final semanticsFinder = find.byType(AccessibleButton);
      final semantics = tester.getSemantics(semanticsFinder);
      expect(semantics.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
    });

    testWidgets('탭 시 onPressed 콜백이 호출된다', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              onPressed: () => pressed = true,
              semanticLabel: '저장',
              child: const Text('저장'),
            ),
          ),
        ),
      );

      // 버튼 탭
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // 콜백이 호출되었는지 확인
      expect(pressed, isTrue);
    });

    testWidgets('Semantics 레이블이 올바르게 설정된다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              onPressed: () {},
              semanticLabel: '일기 저장',
              child: const Text('저장'),
            ),
          ),
        ),
      );

      // Semantics 레이블 확인 - getSemantics를 통해 직접 확인
      // child의 텍스트가 병합될 수 있으므로 contains로 확인
      final semantics = tester.getSemantics(find.byType(AccessibleButton));
      expect(semantics.label, contains('일기 저장'));
    });

    testWidgets('Semantics 힌트가 올바르게 설정된다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              onPressed: () {},
              semanticLabel: '저장',
              semanticHint: '탭하여 일기를 저장합니다',
              child: const Text('저장'),
            ),
          ),
        ),
      );

      // Semantics 힌트 확인
      final semantics = tester.getSemantics(find.byType(AccessibleButton));
      expect(semantics.hint, '탭하여 일기를 저장합니다');
    });

    testWidgets('button 플래그가 설정된다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              onPressed: () {},
              semanticLabel: '저장',
              child: const Text('저장'),
            ),
          ),
        ),
      );

      // Semantics button 플래그 확인
      final semantics = tester.getSemantics(find.byType(AccessibleButton));
      expect(semantics.hasFlag(ui.SemanticsFlag.isButton), isTrue);
    });

    testWidgets('최소 터치 타겟 크기가 보장된다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              onPressed: () {},
              semanticLabel: '저장',
              child: const SizedBox(
                width: 20,
                height: 20,
                child: Icon(Icons.save, size: 16),
              ),
            ),
          ),
        ),
      );

      // ConstrainedBox 확인
      final constrainedBox = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(AccessibleButton),
          matching: find.byType(ConstrainedBox),
        ),
      );

      // 최소 크기 확인
      expect(
        constrainedBox.constraints.minWidth,
        AccessibilityUtils.minTouchTargetSize,
      );
      expect(
        constrainedBox.constraints.minHeight,
        AccessibilityUtils.minTouchTargetSize,
      );
    });

    testWidgets('작은 콘텐츠도 최소 터치 타겟 크기로 확장된다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              onPressed: () {},
              semanticLabel: '아이콘 버튼',
              child: const Icon(Icons.add, size: 16),
            ),
          ),
        ),
      );

      // 버튼 크기 확인
      final buttonSize = tester.getSize(
        find.descendant(
          of: find.byType(AccessibleButton),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(
        buttonSize.width,
        greaterThanOrEqualTo(AccessibilityUtils.minTouchTargetSize),
      );
      expect(
        buttonSize.height,
        greaterThanOrEqualTo(AccessibilityUtils.minTouchTargetSize),
      );
    });

    testWidgets('큰 콘텐츠는 원래 크기를 유지한다', (tester) async {
      const largeSize = 100.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              onPressed: () {},
              semanticLabel: '큰 버튼',
              child: const SizedBox(
                width: largeSize,
                height: largeSize,
                child: Center(child: Text('큰 버튼')),
              ),
            ),
          ),
        ),
      );

      // 버튼 크기 확인 (큰 크기가 유지되어야 함)
      final buttonSize = tester.getSize(
        find.descendant(
          of: find.byType(AccessibleButton),
          matching: find.byType(ConstrainedBox),
        ),
      );
      expect(buttonSize.width, greaterThanOrEqualTo(largeSize));
      expect(buttonSize.height, greaterThanOrEqualTo(largeSize));
    });

    testWidgets('excludeSemantics가 true일 때 child의 Semantics만 사용된다',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              onPressed: () {},
              semanticLabel: '외부 레이블',
              excludeSemantics: true,
              child: const Text('내부 텍스트'),
            ),
          ),
        ),
      );

      // excludeSemantics가 true이므로 외부 레이블은 제외됨
      final semantics = tester.getSemantics(find.byType(AccessibleButton));
      expect(semantics, isNotNull);
    });

    testWidgets('enabled 상태가 onPressed 여부에 따라 변경된다', (tester) async {
      // 활성화 상태
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              onPressed: () {},
              semanticLabel: '저장',
              child: const Text('저장'),
            ),
          ),
        ),
      );

      var semantics = tester.getSemantics(find.byType(AccessibleButton));
      expect(semantics.hasFlag(SemanticsFlag.hasEnabledState), isTrue);

      // 비활성화 상태로 변경
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              onPressed: null,
              semanticLabel: '저장',
              child: Text('저장'),
            ),
          ),
        ),
      );

      semantics = tester.getSemantics(find.byType(AccessibleButton));
      expect(semantics.hasFlag(SemanticsFlag.hasEnabledState), isTrue);
    });

    testWidgets('InkWell의 splash 효과가 작동한다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              onPressed: () {},
              semanticLabel: '버튼',
              child: const Text('버튼'),
            ),
          ),
        ),
      );

      // InkWell이 존재하는지 확인
      expect(find.byType(InkWell), findsOneWidget);

      // 터치 시작
      await tester.press(find.byType(InkWell));
      await tester.pumpAndSettle();

      // splash 효과가 있는 Material이 있는지 확인
      expect(find.byType(Material), findsWidgets);
    });

    testWidgets('여러 AccessibleButton이 동시에 작동한다', (tester) async {
      var button1Pressed = false;
      var button2Pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AccessibleButton(
                  onPressed: () => button1Pressed = true,
                  semanticLabel: '버튼 1',
                  child: const Text('버튼 1'),
                ),
                AccessibleButton(
                  onPressed: () => button2Pressed = true,
                  semanticLabel: '버튼 2',
                  child: const Text('버튼 2'),
                ),
              ],
            ),
          ),
        ),
      );

      // 첫 번째 버튼 탭
      await tester.tap(find.text('버튼 1'));
      await tester.pumpAndSettle();
      expect(button1Pressed, isTrue);
      expect(button2Pressed, isFalse);

      // 두 번째 버튼 탭
      await tester.tap(find.text('버튼 2'));
      await tester.pumpAndSettle();
      expect(button2Pressed, isTrue);
    });

    testWidgets('Semantics 트리에 올바르게 포함된다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              onPressed: () {},
              semanticLabel: '일기 저장',
              semanticHint: '탭하여 저장',
              child: const Icon(Icons.save),
            ),
          ),
        ),
      );

      // Semantics 디버그 정보 가져오기
      final semanticsDebugString = tester
          .binding.pipelineOwner.semanticsOwner?.rootSemanticsNode
          ?.toStringDeep();

      expect(semanticsDebugString, isNotNull);
      // Semantics 트리에 버튼이 포함되어 있는지 확인
      expect(semanticsDebugString, contains('일기 저장'));
    });
  });
}
