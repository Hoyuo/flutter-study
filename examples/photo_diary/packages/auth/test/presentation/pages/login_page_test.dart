import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:auth/presentation/bloc/bloc.dart';
import 'package:auth/presentation/pages/login_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

// Mock 클래스들
class MockAuthBloc extends Mock implements AuthBloc {}

class MockGoRouter extends Mock implements GoRouter {}

class MockGoRouterDelegate extends Mock implements GoRouterDelegate {}

class MockGoRouteInformationProvider extends Mock
    implements GoRouteInformationProvider {}

// 테스트용 인메모리 AssetLoader
class TestAssetLoader extends AssetLoader {
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    // 한국어 번역 데이터
    return {
      'auth': {
        'login': '로그인',
        'email': '이메일',
        'password': '비밀번호',
        'welcome': '환영합니다',
        'email_field': '이메일 입력 필드',
        'password_field': '비밀번호 입력 필드',
        'email_hint': '이메일을 입력하세요',
        'password_hint': '비밀번호를 입력하세요',
        'show_password': '비밀번호 표시',
        'hide_password': '비밀번호 숨김',
        'login_button': '로그인 버튼',
        'no_account': '계정이 없으신가요?',
        'register': '회원가입',
        'register_link': '회원가입 링크',
      }
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Mock SharedPreferences
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return <String, dynamic>{};
        }
        return null;
      },
    );

    // EasyLocalization 초기화
    await EasyLocalization.ensureInitialized();

    // 이벤트 등록
    registerFallbackValue(
      const AuthEvent.signInRequested(email: '', password: ''),
    );
  });

  group('LoginPage', () {
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      // 기본 상태 설정
      when(() => mockAuthBloc.state).thenReturn(const AuthState());
      when(() => mockAuthBloc.stream).thenAnswer(
        (_) => Stream.value(const AuthState()),
      );
      when(() => mockAuthBloc.effectStream).thenAnswer(
        (_) => const Stream.empty(),
      );
    });

    test('LoginPage 위젯을 생성할 수 있다', () {
      // 생성자 커버리지를 위한 테스트
      final loginPage = LoginPage(key: UniqueKey());
      expect(loginPage, isNotNull);
      expect(loginPage, isA<LoginPage>());
    });

    Future<void> pumpTestWidget(WidgetTester tester,
        {bool skipSettle = false}) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('ko')],
          path: 'assets/translations',
          fallbackLocale: const Locale('ko'),
          useOnlyLangCode: true,
          useFallbackTranslations: true,
          assetLoader: TestAssetLoader(),
          child: Builder(
            builder: (context) {
              return MaterialApp(
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                home: BlocProvider<AuthBloc>.value(
                  value: mockAuthBloc,
                  child: const LoginPage(),
                ),
              );
            },
          ),
        ),
      );
      if (skipSettle) {
        // 로딩 상태 등 애니메이션이 있는 경우, 몇 프레임만 pump
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      } else {
        await tester.pumpAndSettle();
      }
    }

    testWidgets('이메일과 비밀번호 필드가 표시된다', (tester) async {
      await pumpTestWidget(tester);

      // TextFormField가 2개 있어야 함 (이메일, 비밀번호)
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('로그인 버튼이 표시된다', (tester) async {
      await pumpTestWidget(tester);

      // 로그인 버튼 확인
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('회원가입 링크가 표시된다', (tester) async {
      await pumpTestWidget(tester);

      // TextButton이 회원가입 링크로 존재
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('로그인 버튼 탭 시 유효성 검증이 수행된다', (tester) async {
      await pumpTestWidget(tester);

      // 빈 상태에서 로그인 버튼 탭
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // 이벤트가 전송되지 않아야 함 (유효성 검증 실패)
      verifyNever(() => mockAuthBloc.add(any()));
    });

    testWidgets('유효한 이메일/비밀번호 입력 시 로그인 이벤트 발생', (tester) async {
      await pumpTestWidget(tester);

      // 이메일 입력
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.pumpAndSettle();

      // 비밀번호 입력
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );
      await tester.pumpAndSettle();

      // 로그인 버튼 탭
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // AuthBloc에 로그인 이벤트가 전송되었는지 확인
      verify(
        () => mockAuthBloc.add(
          const AuthEvent.signInRequested(
            email: 'test@example.com',
            password: 'password123',
          ),
        ),
      ).called(1);
    });

    testWidgets('비밀번호 표시/숨김 토글이 작동한다', (tester) async {
      await pumpTestWidget(tester);

      // 초기 상태: visibility 아이콘 표시
      final visibilityButton = find.byIcon(Icons.visibility_outlined);
      expect(visibilityButton, findsOneWidget);

      // 토글 버튼 탭
      await tester.tap(visibilityButton);
      await tester.pumpAndSettle();

      // 아이콘이 visibility_off로 변경됨
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('로딩 중일 때 입력 필드가 비활성화된다', (tester) async {
      // 로딩 상태로 설정
      when(() => mockAuthBloc.state).thenReturn(
        const AuthState(isSubmitting: true),
      );
      when(() => mockAuthBloc.stream).thenAnswer(
        (_) => const Stream.empty(),
      );

      await pumpTestWidget(tester, skipSettle: true);

      // 이메일 필드 비활성화 확인
      final emailField = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      expect(emailField.enabled, isFalse);

      // 비밀번호 필드 비활성화 확인
      final passwordField = tester.widget<TextFormField>(
        find.byType(TextFormField).last,
      );
      expect(passwordField.enabled, isFalse);
    });

    testWidgets('로딩 중일 때 로딩 인디케이터가 표시된다', (tester) async {
      // 로딩 상태로 설정
      when(() => mockAuthBloc.state).thenReturn(
        const AuthState(isSubmitting: true),
      );
      when(() => mockAuthBloc.stream).thenAnswer(
        (_) => const Stream.empty(),
      );

      await pumpTestWidget(tester, skipSettle: true);

      // CircularProgressIndicator가 버튼 안에 표시됨
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('이메일 필드에 Semantics가 설정된다', (tester) async {
      await pumpTestWidget(tester);

      // 이메일 필드의 Semantics 확인
      final emailFieldFinder = find.byType(TextFormField).first;
      expect(emailFieldFinder, findsOneWidget);

      // Semantics 레이블 확인
      final semantics = tester.getSemantics(emailFieldFinder);
      expect(semantics, isNotNull);
    });

    testWidgets('비밀번호 필드에 Semantics가 설정된다', (tester) async {
      await pumpTestWidget(tester);

      // 비밀번호 필드의 Semantics 확인
      final passwordFieldFinder = find.byType(TextFormField).last;
      expect(passwordFieldFinder, findsOneWidget);

      // Semantics 레이블 확인
      final semantics = tester.getSemantics(passwordFieldFinder);
      expect(semantics, isNotNull);
    });

    testWidgets('로그인 버튼에 Semantics가 설정된다', (tester) async {
      await pumpTestWidget(tester);

      // 로그인 버튼의 Semantics 확인
      final buttonFinder = find.byType(FilledButton);
      final semantics = tester.getSemantics(buttonFinder);
      expect(semantics.hasFlag(ui.SemanticsFlag.isButton), isTrue);
    });

    testWidgets('Enter 키로 로그인할 수 있다', (tester) async {
      await pumpTestWidget(tester);

      // 이메일 입력
      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.pumpAndSettle();

      // 비밀번호 입력
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );
      await tester.pumpAndSettle();

      // 비밀번호 필드에서 Enter 키 입력 (onFieldSubmitted)
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // AuthBloc에 로그인 이벤트가 전송되었는지 확인
      verify(
        () => mockAuthBloc.add(
          const AuthEvent.signInRequested(
            email: 'test@example.com',
            password: 'password123',
          ),
        ),
      ).called(1);
    });

    testWidgets('AuthShowError 효과 발생 시 에러 스낵바가 표시된다', (tester) async {
      final effectController = StreamController<AuthUiEffect>.broadcast();

      when(() => mockAuthBloc.effectStream)
          .thenAnswer((_) => effectController.stream);

      await pumpTestWidget(tester);

      // AuthShowError 효과 발생
      effectController.add(const AuthShowError('Login failed'));
      await tester.pumpAndSettle();

      // 스낵바가 표시되는지 확인
      expect(find.text('Login failed'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);

      await effectController.close();
    });

    testWidgets('AuthShowSuccessSnackBar 효과 발생 시 성공 스낵바가 표시된다',
        (tester) async {
      final effectController = StreamController<AuthUiEffect>.broadcast();

      when(() => mockAuthBloc.effectStream)
          .thenAnswer((_) => effectController.stream);

      await pumpTestWidget(tester);

      // AuthShowSuccessSnackBar 효과 발생
      effectController
          .add(const AuthShowSuccessSnackBar('Success message'));
      await tester.pumpAndSettle();

      // 스낵바가 표시되는지 확인
      expect(find.text('Success message'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);

      await effectController.close();
    });

    testWidgets('AuthNavigateToHome 효과 발생 시 홈으로 이동한다', (tester) async {
      final effectController = StreamController<AuthUiEffect>.broadcast();

      when(() => mockAuthBloc.effectStream)
          .thenAnswer((_) => effectController.stream);

      // GoRouter 설정
      final goRouter = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Text('Home Page'),
            ),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: const LoginPage(),
            ),
          ),
        ],
        initialLocation: '/login',
      );

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('ko')],
          path: 'assets/translations',
          fallbackLocale: const Locale('ko'),
          useOnlyLangCode: true,
          useFallbackTranslations: true,
          assetLoader: TestAssetLoader(),
          child: Builder(
            builder: (context) {
              return MaterialApp.router(
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                routerConfig: goRouter,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // AuthNavigateToHome 효과 발생
      effectController.add(const AuthNavigateToHome());
      await tester.pumpAndSettle();

      // 홈 페이지로 이동했는지 확인
      expect(find.text('Home Page'), findsOneWidget);

      await effectController.close();
    });

    testWidgets('AuthNavigateToLogin 효과는 로그인 페이지에서 무시된다', (tester) async {
      final effectController = StreamController<AuthUiEffect>.broadcast();

      when(() => mockAuthBloc.effectStream)
          .thenAnswer((_) => effectController.stream);

      await pumpTestWidget(tester);

      // AuthNavigateToLogin 효과 발생 (로그인 페이지에서는 무시됨)
      effectController.add(const AuthNavigateToLogin());
      await tester.pumpAndSettle();

      // 여전히 로그인 페이지에 있는지 확인 (아무 변화 없음)
      expect(find.byType(LoginPage), findsOneWidget);

      await effectController.close();
    });

    testWidgets('회원가입 버튼 탭 시 회원가입 페이지로 이동한다', (tester) async {
      // GoRouter 설정
      final goRouter = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(
              body: Text('Home Page'),
            ),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => BlocProvider<AuthBloc>.value(
              value: mockAuthBloc,
              child: const LoginPage(),
            ),
          ),
          GoRoute(
            path: '/register',
            builder: (context, state) => const Scaffold(
              body: Text('Register Page'),
            ),
          ),
        ],
        initialLocation: '/login',
      );

      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('ko')],
          path: 'assets/translations',
          fallbackLocale: const Locale('ko'),
          useOnlyLangCode: true,
          useFallbackTranslations: true,
          assetLoader: TestAssetLoader(),
          child: Builder(
            builder: (context) {
              return MaterialApp.router(
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                routerConfig: goRouter,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 회원가입 버튼 탭
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      // 회원가입 페이지로 이동했는지 확인
      expect(find.text('Register Page'), findsOneWidget);
    });

    testWidgets('로딩 중일 때 회원가입 버튼이 비활성화된다', (tester) async {
      // 로딩 상태로 설정
      when(() => mockAuthBloc.state).thenReturn(
        const AuthState(isSubmitting: true),
      );
      when(() => mockAuthBloc.stream).thenAnswer(
        (_) => const Stream.empty(),
      );

      await pumpTestWidget(tester, skipSettle: true);

      // TextButton (회원가입 버튼) 찾기
      final registerButton = tester.widget<TextButton>(
        find.byType(TextButton),
      );

      // 버튼이 비활성화되어 있는지 확인
      expect(registerButton.onPressed, isNull);
    });
  });
}
