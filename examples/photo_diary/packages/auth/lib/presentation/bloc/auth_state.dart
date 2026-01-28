import 'package:auth/domain/entities/user.dart';
import 'package:core/error/failure.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

/// 인증 상태를 나타내는 enum
///
/// - [unknown]: 인증 상태를 아직 확인하지 않음 (초기 상태)
/// - [authenticated]: 사용자가 인증됨
/// - [unauthenticated]: 사용자가 인증되지 않음
enum AuthStatus {
  /// 인증 상태 확인 전
  unknown,

  /// 인증됨
  authenticated,

  /// 인증되지 않음
  unauthenticated,
}

/// 인증 관련 상태를 정의하는 클래스
///
/// Freezed를 사용하여 불변 상태 클래스를 생성합니다.
/// UI는 이 상태를 구독하여 화면을 업데이트합니다.
@freezed
class AuthState with _$AuthState {
  /// 기본 생성자
  ///
  /// [status]: 현재 인증 상태 (기본값: unknown)
  /// [user]: 현재 로그인한 사용자 정보 (null 가능)
  /// [isSubmitting]: 요청 진행 중 여부 (기본값: false)
  /// [failure]: 발생한 에러 정보 (null 가능)
  const factory AuthState({
    @Default(AuthStatus.unknown) AuthStatus status,
    User? user,
    @Default(false) bool isSubmitting,
    Failure? failure,
  }) = _AuthState;
}
