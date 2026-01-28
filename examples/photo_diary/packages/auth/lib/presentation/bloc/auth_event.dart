import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_event.freezed.dart';

/// 인증 관련 이벤트를 정의하는 sealed class
///
/// Freezed를 사용하여 불변 이벤트 클래스들을 생성합니다.
/// 각 이벤트는 사용자의 인증 관련 액션을 나타냅니다.
@freezed
sealed class AuthEvent with _$AuthEvent {
  /// 로그인 요청 이벤트
  ///
  /// [email]: 사용자 이메일
  /// [password]: 사용자 비밀번호
  const factory AuthEvent.signInRequested({
    required String email,
    required String password,
  }) = SignInRequested;

  /// 회원가입 요청 이벤트
  ///
  /// [email]: 사용자 이메일
  /// [password]: 사용자 비밀번호
  /// [displayName]: 사용자 표시 이름
  const factory AuthEvent.signUpRequested({
    required String email,
    required String password,
    required String displayName,
  }) = SignUpRequested;

  /// 로그아웃 요청 이벤트
  const factory AuthEvent.signOutRequested() = SignOutRequested;

  /// 인증 상태 확인 이벤트
  ///
  /// 앱 시작 시 또는 필요 시 현재 인증 상태를 확인합니다.
  const factory AuthEvent.checkAuthStatus() = CheckAuthStatus;
}
