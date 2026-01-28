import 'package:auth/domain/entities/user.dart';
import 'package:auth/domain/usecases/get_current_user_usecase.dart';
import 'package:auth/domain/usecases/sign_in_with_email_usecase.dart';
import 'package:auth/domain/usecases/sign_out_usecase.dart';
import 'package:auth/domain/usecases/sign_up_usecase.dart';
import 'package:auth/presentation/bloc/auth_bloc.dart';
import 'package:auth/presentation/bloc/auth_event.dart';
import 'package:auth/presentation/bloc/auth_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:core/error/failure.dart';
import 'package:core/types/usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

// Mock 클래스 정의
class MockSignInWithEmailUseCase extends Mock
    implements SignInWithEmailUseCase {}

class MockSignUpUseCase extends Mock implements SignUpUseCase {}

class MockSignOutUseCase extends Mock implements SignOutUseCase {}

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

void main() {
  late AuthBloc bloc;
  late MockSignInWithEmailUseCase mockSignInUseCase;
  late MockSignUpUseCase mockSignUpUseCase;
  late MockSignOutUseCase mockSignOutUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;

  // 테스트용 User 데이터
  final testUser = User(
    id: 'test-id-123',
    email: 'test@test.com',
    displayName: '테스트 유저',
    photoUrl: 'https://example.com/photo.jpg',
    createdAt: DateTime(2024, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(const SignInParams(email: '', password: ''));
    registerFallbackValue(const SignUpParams(email: '', password: ''));
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    mockSignInUseCase = MockSignInWithEmailUseCase();
    mockSignUpUseCase = MockSignUpUseCase();
    mockSignOutUseCase = MockSignOutUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();

    bloc = AuthBloc(
      signInUseCase: mockSignInUseCase,
      signUpUseCase: mockSignUpUseCase,
      signOutUseCase: mockSignOutUseCase,
      getCurrentUserUseCase: mockGetCurrentUserUseCase,
    );
  });

  tearDown(() => bloc.close());

  group('AuthBloc', () {
    test('초기 상태는 unknown', () {
      expect(bloc.state.status, AuthStatus.unknown);
      expect(bloc.state.user, isNull);
      expect(bloc.state.isSubmitting, isFalse);
      expect(bloc.state.failure, isNull);
    });

    group('로그인 (SignInRequested)', () {
      blocTest<AuthBloc, AuthState>(
        '로그인 성공 시 authenticated 상태로 변경',
        build: () {
          when(() => mockSignInUseCase(any()))
              .thenAnswer((_) async => Right(testUser));
          return bloc;
        },
        act: (bloc) => bloc.add(const AuthEvent.signInRequested(
          email: 'test@test.com',
          password: 'password123',
        )),
        expect: () => [
          // 로딩 시작
          isA<AuthState>()
              .having((s) => s.isSubmitting, 'isSubmitting', true)
              .having((s) => s.failure, 'failure', isNull),
          // 로그인 성공
          isA<AuthState>()
              .having((s) => s.isSubmitting, 'isSubmitting', false)
              .having((s) => s.status, 'status', AuthStatus.authenticated)
              .having((s) => s.user, 'user', testUser)
              .having((s) => s.failure, 'failure', isNull),
        ],
        verify: (_) {
          verify(() => mockSignInUseCase(any())).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        '로그인 실패 시 failure 설정 및 unauthenticated 상태',
        build: () {
          when(() => mockSignInUseCase(any())).thenAnswer(
            (_) async => const Left(Failure.auth(message: '잘못된 비밀번호')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const AuthEvent.signInRequested(
          email: 'test@test.com',
          password: 'wrong-password',
        )),
        expect: () => [
          // 로딩 시작
          isA<AuthState>()
              .having((s) => s.isSubmitting, 'isSubmitting', true)
              .having((s) => s.failure, 'failure', isNull),
          // 로그인 실패
          isA<AuthState>()
              .having((s) => s.isSubmitting, 'isSubmitting', false)
              .having((s) => s.status, 'status', AuthStatus.unauthenticated)
              .having((s) => s.failure, 'failure', isNotNull)
              .having((s) => s.failure?.message, 'failure.message', '잘못된 비밀번호'),
        ],
      );
    });

    group('회원가입 (SignUpRequested)', () {
      blocTest<AuthBloc, AuthState>(
        '회원가입 성공 시 authenticated 상태로 변경',
        build: () {
          when(() => mockSignUpUseCase(any()))
              .thenAnswer((_) async => Right(testUser));
          return bloc;
        },
        act: (bloc) => bloc.add(const AuthEvent.signUpRequested(
          email: 'test@test.com',
          password: 'password123',
          displayName: '테스트 유저',
        )),
        expect: () => [
          // 로딩 시작
          isA<AuthState>()
              .having((s) => s.isSubmitting, 'isSubmitting', true)
              .having((s) => s.failure, 'failure', isNull),
          // 회원가입 성공
          isA<AuthState>()
              .having((s) => s.isSubmitting, 'isSubmitting', false)
              .having((s) => s.status, 'status', AuthStatus.authenticated)
              .having((s) => s.user, 'user', testUser)
              .having((s) => s.failure, 'failure', isNull),
        ],
        verify: (_) {
          verify(() => mockSignUpUseCase(any())).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        '회원가입 실패 시 failure 설정',
        build: () {
          when(() => mockSignUpUseCase(any())).thenAnswer(
            (_) async => const Left(Failure.auth(message: '이미 존재하는 이메일입니다')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const AuthEvent.signUpRequested(
          email: 'existing@test.com',
          password: 'password123',
          displayName: '테스트',
        )),
        expect: () => [
          // 로딩 시작
          isA<AuthState>().having((s) => s.isSubmitting, 'isSubmitting', true),
          // 회원가입 실패
          isA<AuthState>()
              .having((s) => s.isSubmitting, 'isSubmitting', false)
              .having((s) => s.status, 'status', AuthStatus.unauthenticated)
              .having((s) => s.failure, 'failure', isNotNull)
              .having((s) => s.failure?.message, 'failure.message',
                  '이미 존재하는 이메일입니다'),
        ],
      );
    });

    group('로그아웃 (SignOutRequested)', () {
      blocTest<AuthBloc, AuthState>(
        '로그아웃 성공 시 unauthenticated 상태로 변경',
        build: () {
          when(() => mockSignOutUseCase(const NoParams())).thenAnswer(
            (_) async => const Right(unit),
          );
          return bloc;
        },
        seed: () => AuthState(
          status: AuthStatus.authenticated,
          user: testUser,
        ),
        act: (bloc) => bloc.add(const AuthEvent.signOutRequested()),
        expect: () => [
          // 로딩 시작
          isA<AuthState>()
              .having((s) => s.isSubmitting, 'isSubmitting', true)
              .having((s) => s.user, 'user', testUser),
          // 로그아웃 성공
          isA<AuthState>()
              .having((s) => s.isSubmitting, 'isSubmitting', false)
              .having((s) => s.status, 'status', AuthStatus.unauthenticated)
              .having((s) => s.user, 'user', isNull)
              .having((s) => s.failure, 'failure', isNull),
        ],
        verify: (_) {
          verify(() => mockSignOutUseCase(any())).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        '로그아웃 실패 시 failure 설정 (상태는 유지)',
        build: () {
          when(() => mockSignOutUseCase(const NoParams())).thenAnswer(
            (_) async => const Left(Failure.network(message: '네트워크 오류')),
          );
          return bloc;
        },
        seed: () => AuthState(
          status: AuthStatus.authenticated,
          user: testUser,
        ),
        act: (bloc) => bloc.add(const AuthEvent.signOutRequested()),
        expect: () => [
          // 로딩 시작
          isA<AuthState>().having((s) => s.isSubmitting, 'isSubmitting', true),
          // 로그아웃 실패
          isA<AuthState>()
              .having((s) => s.isSubmitting, 'isSubmitting', false)
              .having((s) => s.failure, 'failure', isNotNull)
              .having((s) => s.failure?.message, 'failure.message', '네트워크 오류'),
        ],
      );
    });

    group('인증 상태 확인 (CheckAuthStatus)', () {
      blocTest<AuthBloc, AuthState>(
        '사용자가 로그인되어 있을 때 authenticated 상태로 변경',
        build: () {
          when(() => mockGetCurrentUserUseCase(const NoParams())).thenAnswer(
            (_) async => Right(testUser),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const AuthEvent.checkAuthStatus()),
        expect: () => [
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.authenticated)
              .having((s) => s.user, 'user', testUser),
        ],
        verify: (_) {
          verify(() => mockGetCurrentUserUseCase(any())).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        '사용자가 로그인되어 있지 않을 때 unauthenticated 상태로 변경',
        build: () {
          when(() => mockGetCurrentUserUseCase(const NoParams())).thenAnswer(
            (_) async => const Left(Failure.auth(message: '사용자 없음')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const AuthEvent.checkAuthStatus()),
        expect: () => [
          isA<AuthState>()
              .having((s) => s.status, 'status', AuthStatus.unauthenticated)
              .having((s) => s.user, 'user', isNull),
        ],
      );
    });
  });
}
