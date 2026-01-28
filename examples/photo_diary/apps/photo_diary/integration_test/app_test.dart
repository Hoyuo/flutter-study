import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:photo_diary/main.dart' as app;
import 'package:auth/auth.dart';
import 'package:diary/diary.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('앱 통합 테스트', () {
    testWidgets('로그인 플로우 테스트', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 스플래시 화면 대기
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 로그인 화면으로 리다이렉트 확인
      expect(find.byType(LoginPage), findsOneWidget);

      // 이메일 입력
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@test.com',
      );

      // 비밀번호 입력
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );

      // 로그인 버튼 탭
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // 홈 화면 도달 확인
      expect(find.byType(DiaryListPage), findsOneWidget);
    });

    testWidgets('일기 생성 플로우 테스트', (tester) async {
      // 로그인 후
      // FAB 탭
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // 일기 작성 화면 확인
      expect(find.byType(DiaryEditPage), findsOneWidget);

      // 제목 입력
      await tester.enterText(find.byKey(const Key('title_field')), '테스트 일기');

      // 내용 입력
      await tester.enterText(
        find.byKey(const Key('content_field')),
        '오늘의 테스트 내용입니다.',
      );

      // 저장 버튼 탭
      await tester.tap(find.byKey(const Key('save_button')));
      await tester.pumpAndSettle();

      // 목록 화면으로 복귀 확인
      expect(find.byType(DiaryListPage), findsOneWidget);

      // 새 일기가 목록에 표시되는지 확인
      expect(find.text('테스트 일기'), findsOneWidget);
    });

    testWidgets('설정 변경 테스트', (tester) async {
      // 설정 화면 이동
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // 테마 변경
      await tester.tap(find.text('테마'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('다크 모드'));
      await tester.pumpAndSettle();

      // 다크 모드 적용 확인
      final theme = Theme.of(tester.element(find.byType(MaterialApp)));
      expect(theme.brightness, Brightness.dark);
    });

    testWidgets('검색 기능 테스트', (tester) async {
      // 검색 화면 이동
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // 검색어 입력
      await tester.enterText(find.byType(TextField), '테스트');
      await tester.pumpAndSettle(const Duration(milliseconds: 500)); // debounce

      // 검색 결과 확인
      expect(find.byType(DiaryCard), findsWidgets);
    });
  });
}
