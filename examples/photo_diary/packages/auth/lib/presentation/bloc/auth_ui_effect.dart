import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_ui_effect.freezed.dart';

/// 인증 관련 일회성 UI 효과를 정의하는 sealed class
///
/// BlocUiEffect 패턴을 사용하여 상태와 분리된 일회성 이벤트를 처리합니다.
/// 예: 스낵바 표시, 화면 전환 등
///
/// 이러한 효과들은 상태에 저장되지 않고 한 번만 발생해야 합니다.
@freezed
sealed class AuthUiEffect with _$AuthUiEffect {
  /// 에러 메시지 표시 효과
  ///
  /// [message]: 사용자에게 표시할 에러 메시지
  const factory AuthUiEffect.showError(String message) = AuthShowError;

  /// 홈 화면으로 이동 효과
  ///
  /// 로그인/회원가입 성공 후 메인 화면으로 전환
  const factory AuthUiEffect.navigateToHome() = AuthNavigateToHome;

  /// 로그인 화면으로 이동 효과
  ///
  /// 로그아웃 후 또는 인증 실패 시 로그인 화면으로 전환
  const factory AuthUiEffect.navigateToLogin() = AuthNavigateToLogin;

  /// 성공 스낵바 표시 효과
  ///
  /// [message]: 사용자에게 표시할 성공 메시지
  const factory AuthUiEffect.showSuccessSnackBar(String message) =
      AuthShowSuccessSnackBar;
}
