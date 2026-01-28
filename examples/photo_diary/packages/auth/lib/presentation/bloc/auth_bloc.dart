import 'package:auth/domain/usecases/get_current_user_usecase.dart';
import 'package:auth/domain/usecases/sign_in_with_email_usecase.dart';
import 'package:auth/domain/usecases/sign_out_usecase.dart';
import 'package:auth/domain/usecases/sign_up_usecase.dart';
import 'package:auth/presentation/bloc/auth_event.dart';
import 'package:auth/presentation/bloc/auth_state.dart';
import 'package:auth/presentation/bloc/auth_ui_effect.dart';
import 'package:core/bloc/bloc_ui_effect_mixin.dart';
import 'package:core/types/usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 인증 관련 비즈니스 로직을 처리하는 BLoC
///
/// BlocUiEffectMixin을 사용하여 상태 변경과 일회성 UI 효과를 분리합니다.
/// - 상태 변경: emit()으로 처리 (UI가 구독)
/// - UI 효과: emitWithEffect()로 처리 (한 번만 실행)
class AuthBloc extends Bloc<AuthEvent, AuthState>
    with BlocUiEffectMixin<AuthUiEffect, AuthState> {
  final SignInWithEmailUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final SignOutUseCase _signOutUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  /// 생성자
  ///
  /// 모든 인증 관련 use case를 주입받습니다.
  AuthBloc({
    required SignInWithEmailUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required SignOutUseCase signOutUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
  })  : _signInUseCase = signInUseCase,
        _signUpUseCase = signUpUseCase,
        _signOutUseCase = signOutUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        super(const AuthState()) {
    // 이벤트 핸들러 등록
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  /// 로그인 요청 처리
  ///
  /// 1. 로딩 상태로 전환
  /// 2. SignInWithEmailUseCase 실행
  /// 3. 성공: 인증 상태로 전환 + 홈 화면 이동 효과
  /// 4. 실패: 에러 상태로 전환 + 에러 메시지 표시 효과
  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    // 로딩 시작
    emit(state.copyWith(
      isSubmitting: true,
      failure: null,
    ));

    // Use case 실행
    final result = await _signInUseCase(SignInParams(
      email: event.email,
      password: event.password,
    ));

    // 결과 처리
    result.fold(
      // 실패
      (failure) {
        emit(state.copyWith(
          isSubmitting: false,
          failure: failure,
          status: AuthStatus.unauthenticated,
        ));
        emitUiEffect(AuthUiEffect.showError(failure.message));
      },
      // 성공
      (user) {
        emit(state.copyWith(
          isSubmitting: false,
          failure: null,
          status: AuthStatus.authenticated,
          user: user,
        ));
        emitUiEffect(const AuthUiEffect.navigateToHome());
      },
    );
  }

  /// 회원가입 요청 처리
  ///
  /// 1. 로딩 상태로 전환
  /// 2. SignUpUseCase 실행
  /// 3. 성공: 인증 상태로 전환 + 홈 화면 이동 효과 + 성공 메시지
  /// 4. 실패: 에러 상태로 전환 + 에러 메시지 표시 효과
  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    // 로딩 시작
    emit(state.copyWith(
      isSubmitting: true,
      failure: null,
    ));

    // Use case 실행
    final result = await _signUpUseCase(SignUpParams(
      email: event.email,
      password: event.password,
      displayName: event.displayName,
    ));

    // 결과 처리
    result.fold(
      // 실패
      (failure) {
        emit(state.copyWith(
          isSubmitting: false,
          failure: failure,
          status: AuthStatus.unauthenticated,
        ));
        emitUiEffect(AuthUiEffect.showError(failure.message));
      },
      // 성공
      (user) {
        emit(state.copyWith(
          isSubmitting: false,
          failure: null,
          status: AuthStatus.authenticated,
          user: user,
        ));
        emitUiEffect(const AuthUiEffect.showSuccessSnackBar('회원가입이 완료되었습니다'));
        emitUiEffect(const AuthUiEffect.navigateToHome());
      },
    );
  }

  /// 로그아웃 요청 처리
  ///
  /// 1. 로딩 상태로 전환
  /// 2. SignOutUseCase 실행
  /// 3. 성공: 미인증 상태로 전환 + 로그인 화면 이동 효과
  /// 4. 실패: 에러 메시지 표시 효과 (상태는 그대로 유지)
  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // 로딩 시작
    emit(state.copyWith(
      isSubmitting: true,
      failure: null,
    ));

    // Use case 실행
    final result = await _signOutUseCase(const NoParams());

    // 결과 처리
    result.fold(
      // 실패
      (failure) {
        emit(state.copyWith(
          isSubmitting: false,
          failure: failure,
        ));
        emitUiEffect(AuthUiEffect.showError(failure.message));
      },
      // 성공
      (_) {
        emit(state.copyWith(
          isSubmitting: false,
          failure: null,
          status: AuthStatus.unauthenticated,
          user: null,
        ));
        emitUiEffect(const AuthUiEffect.navigateToLogin());
      },
    );
  }

  /// 인증 상태 확인 처리
  ///
  /// 앱 시작 시 또는 필요 시 현재 로그인 사용자 정보를 확인합니다.
  /// 1. GetCurrentUserUseCase 실행
  /// 2. 사용자 있음: 인증 상태로 전환
  /// 3. 사용자 없음: 미인증 상태로 전환
  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    // Use case 실행
    final result = await _getCurrentUserUseCase(const NoParams());

    // 결과 처리
    result.fold(
      // 실패 또는 사용자 없음
      (failure) {
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
        ));
      },
      // 성공 - 사용자 있음
      (user) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        ));
      },
    );
  }
}
