import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:core/core.dart';
import 'package:settings/domain/entities/entities.dart';
import 'package:settings/presentation/bloc/bloc.dart';
import 'package:settings/presentation/pages/settings_page.dart';
import 'package:settings/presentation/widgets/widgets.dart';

// Mock 클래스들
class MockSettingsBloc extends Mock implements SettingsBloc {}

void main() {
  setUpAll(() {
    // 이벤트 등록
    registerFallbackValue(const SettingsEvent.loadSettings());
  });

  group('SettingsPage', () {
    late MockSettingsBloc mockSettingsBloc;

    // 테스트용 설정 데이터
    final testSettings = const AppSettings(
      themeMode: ThemeMode.light,
      languageCode: 'ko',
      notificationsEnabled: true,
      biometricLockEnabled: false,
    );

    setUp(() {
      mockSettingsBloc = MockSettingsBloc();
      // 기본 상태 설정
      when(() => mockSettingsBloc.state).thenReturn(
        SettingsState(settings: testSettings),
      );
      when(() => mockSettingsBloc.stream).thenAnswer(
        (_) => Stream.value(SettingsState(settings: testSettings)),
      );
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: BlocProvider<SettingsBloc>.value(
          value: mockSettingsBloc,
          child: const SettingsPage(),
        ),
      );
    }

    testWidgets('AppBar에 제목이 표시된다', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // AppBar의 제목 확인
      expect(find.text('설정'), findsOneWidget);
    });

    testWidgets('로딩 중일 때 CircularProgressIndicator가 표시된다', (tester) async {
      // 로딩 상태로 설정 (settings가 null)
      when(() => mockSettingsBloc.state).thenReturn(
        const SettingsState(isLoading: true, settings: null),
      );
      when(() => mockSettingsBloc.stream).thenAnswer(
        (_) => Stream.value(
          const SettingsState(isLoading: true, settings: null),
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // 로딩 인디케이터 확인
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('설정이 없을 때 에러 메시지가 표시된다', (tester) async {
      // settings가 null이고 로딩 중이 아닌 상태
      when(() => mockSettingsBloc.state).thenReturn(
        const SettingsState(isLoading: false, settings: null),
      );
      when(() => mockSettingsBloc.stream).thenAnswer(
        (_) => Stream.value(
          const SettingsState(isLoading: false, settings: null),
        ),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 에러 메시지 확인
      expect(find.text('설정을 불러올 수 없습니다.'), findsOneWidget);
    });

    testWidgets('설정 섹션들이 표시된다', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // SettingsSection이 여러 개 표시됨
      expect(find.byType(SettingsSection), findsWidgets);

      // 상단 섹션 제목 확인
      expect(find.text('외관'), findsOneWidget);
      expect(find.text('언어'), findsNWidgets(2)); // 섹션 제목 + 타일 제목
      expect(find.text('보안'), findsOneWidget);
      expect(find.text('알림'), findsOneWidget);
      expect(find.text('앱 정보'), findsOneWidget);

      // 하단 섹션을 보기 위해 스크롤
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.text('기타'), findsOneWidget);
    });

    testWidgets('테마 설정이 표시된다', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 테마 타일 확인
      expect(find.text('테마'), findsOneWidget);
      expect(find.text('라이트'), findsOneWidget);
    });

    testWidgets('언어 설정이 표시된다', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 언어 타일 확인
      expect(find.text('언어'), findsNWidgets(2)); // 섹션 제목 + 타일 제목
      expect(find.text('한국어'), findsOneWidget);
    });

    testWidgets('생체인증 스위치가 작동한다', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 생체인증 타일 찾기
      expect(find.text('생체인증'), findsOneWidget);

      // Switch 찾기 (첫 번째 Switch는 생체인증용)
      final biometricSwitch = find.byType(Switch).first;
      expect(biometricSwitch, findsOneWidget);

      // 초기 상태 확인 (false)
      Switch switchWidget = tester.widget(biometricSwitch);
      expect(switchWidget.value, isFalse);

      // Switch 탭
      await tester.tap(biometricSwitch);
      await tester.pumpAndSettle();

      // 이벤트가 전송되었는지 확인
      verify(
        () => mockSettingsBloc.add(
          const SettingsEvent.toggleBiometricAuth(true),
        ),
      ).called(1);
    });

    testWidgets('푸시 알림 스위치가 작동한다', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 푸시 알림 타일 찾기
      expect(find.text('푸시 알림'), findsOneWidget);

      // Switch 찾기 (두 번째 Switch는 푸시 알림용)
      final notificationSwitch = find.byType(Switch).last;
      expect(notificationSwitch, findsOneWidget);

      // 초기 상태 확인 (true)
      Switch switchWidget = tester.widget(notificationSwitch);
      expect(switchWidget.value, isTrue);

      // Switch 탭
      await tester.tap(notificationSwitch);
      await tester.pumpAndSettle();

      // 이벤트가 전송되었는지 확인
      verify(
        () => mockSettingsBloc.add(
          const SettingsEvent.togglePushNotification(false),
        ),
      ).called(1);
    });

    testWidgets('버전 정보가 표시된다', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 버전 정보 확인
      expect(find.text('버전'), findsOneWidget);
      expect(find.text('1.0.0'), findsOneWidget);
    });

    testWidgets('로그아웃 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 하단 항목을 보기 위해 스크롤
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // 로그아웃 타일 확인
      expect(find.text('로그아웃'), findsOneWidget);
    });

    testWidgets('로그아웃 탭 시 확인 다이얼로그가 표시된다', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 하단 항목을 보기 위해 스크롤
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // 로그아웃 타일 탭
      await tester.tap(find.text('로그아웃'));
      await tester.pumpAndSettle();

      // 다이얼로그 확인
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('정말 로그아웃하시겠습니까?'), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);
    });

    testWidgets('설정 초기화 버튼이 표시된다', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 하단 항목을 보기 위해 스크롤
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // 설정 초기화 타일 확인
      expect(find.text('설정 초기화'), findsOneWidget);
    });

    testWidgets('설정 초기화 탭 시 확인 다이얼로그가 표시된다', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 하단 항목을 보기 위해 스크롤
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // 설정 초기화 타일 탭
      await tester.tap(find.text('설정 초기화'));
      await tester.pumpAndSettle();

      // 다이얼로그 확인
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('모든 설정을 초기화하시겠습니까?'), findsOneWidget);
      expect(find.text('취소'), findsOneWidget);
      expect(find.text('초기화'), findsOneWidget);
    });

    testWidgets('설정 초기화 확인 시 이벤트가 발생한다', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 하단 항목을 보기 위해 스크롤
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // 설정 초기화 타일 탭
      await tester.tap(find.text('설정 초기화'));
      await tester.pumpAndSettle();

      // 다이얼로그에서 초기화 버튼 탭
      await tester.tap(find.text('초기화').last);
      await tester.pumpAndSettle();

      // 이벤트가 전송되었는지 확인
      verify(
        () => mockSettingsBloc.add(const SettingsEvent.resetSettings()),
      ).called(1);
    });

    testWidgets('에러 발생 시 SnackBar가 표시된다', (tester) async {
      // 에러 상태로 설정
      final errorState = SettingsState(
        settings: testSettings,
        failure: const Failure.server(message: 'Server error'),
      );

      when(() => mockSettingsBloc.state).thenReturn(errorState);
      when(() => mockSettingsBloc.stream).thenAnswer(
        (_) => Stream.value(errorState),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // SnackBar가 표시되는지 확인
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('ListView가 스크롤 가능하다', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // ListView 확인
      expect(find.byType(ListView), findsOneWidget);

      // 스크롤 테스트 (처음에는 '외관'이 보이고 스크롤 후 '기타'가 보임)
      expect(find.text('외관'), findsOneWidget);

      // 아래로 스크롤
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // 기타 섹션이 여전히 보임
      expect(find.text('기타'), findsOneWidget);
    });

    testWidgets('SettingsTile이 여러 개 표시된다', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // SettingsTile 위젯 확인
      expect(find.byType(SettingsTile), findsWidgets);
    });

    testWidgets('다크 테마 설정이 올바르게 표시된다', (tester) async {
      // 다크 테마로 설정된 상태
      final darkThemeSettings = const AppSettings(
        themeMode: ThemeMode.dark,
        languageCode: 'ko',
        notificationsEnabled: true,
        biometricLockEnabled: false,
      );

      when(() => mockSettingsBloc.state).thenReturn(
        SettingsState(settings: darkThemeSettings),
      );
      when(() => mockSettingsBloc.stream).thenAnswer(
        (_) => Stream.value(SettingsState(settings: darkThemeSettings)),
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 다크 테마 표시 확인
      expect(find.text('다크'), findsOneWidget);
    });
  });
}
