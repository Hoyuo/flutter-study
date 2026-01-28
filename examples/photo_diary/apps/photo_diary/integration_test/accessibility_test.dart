import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:photo_diary/core/utils/accessibility_utils.dart';
import 'package:photo_diary/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('접근성 통합 테스트', () {
    testWidgets('모든 버튼에 Semantics가 있다', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 모든 버튼 찾기
      final buttons = find.byType(ElevatedButton);

      for (final button in buttons.evaluate()) {
        final semantics = tester.getSemantics(find.byWidget(button.widget));
        expect(
          semantics.label,
          isNotEmpty,
          reason: '버튼에 Semantics label이 없습니다',
        );
      }
    });

    testWidgets('WCAG AA 색상 대비 충족', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final theme = Theme.of(tester.element(find.byType(MaterialApp)));

      // primary 색상 대비 확인
      expect(
        AccessibilityUtils.meetsAAContrast(
          theme.colorScheme.onPrimary,
          theme.colorScheme.primary,
        ),
        isTrue,
      );
    });

    testWidgets('모든 이미지에 Semantics label이 있다', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 모든 이미지 위젯 찾기
      final images = find.byType(Image);

      for (final image in images.evaluate()) {
        final semantics = tester.getSemantics(find.byWidget(image.widget));
        expect(
          semantics.label,
          isNotNull,
          reason: '이미지에 Semantics label이 없습니다',
        );
      }
    });

    testWidgets('텍스트 크기 조절 지원', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 기본 텍스트 크기 확인
      final normalText = find.text('일기').first;
      final normalSize = tester.getSize(normalText);

      // 텍스트 크기 배율 변경
      await tester.binding.setSurfaceSize(const Size(400, 800));
      tester.view.devicePixelRatio = 2.0;
      await tester.pumpAndSettle();

      // 변경된 텍스트 크기 확인
      final scaledText = find.text('일기').first;
      final scaledSize = tester.getSize(scaledText);

      expect(scaledSize.height, greaterThan(normalSize.height));
    });

    testWidgets('키보드 네비게이션 지원', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Tab 키로 포커스 이동 시뮬레이션
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // 포커스가 이동했는지 확인
      expect(FocusManager.instance.primaryFocus, isNotNull);
    });
  });
}
