/// 현재 로그인한 사용자 정보를 제공하는 서비스 인터페이스
///
/// Repository에서 userId가 필요한 경우 이 서비스를 주입받아 사용합니다.
abstract class CurrentUserService {
  /// 현재 로그인한 사용자의 ID를 반환
  ///
  /// 로그인하지 않은 경우 null 반환
  String? get currentUserId;

  /// 현재 로그인한 사용자의 ID를 반환 (null이면 예외 발생)
  ///
  /// 로그인하지 않은 상태에서 호출하면 [StateError] 발생
  String get requireCurrentUserId;

  /// 로그인 여부 확인
  bool get isLoggedIn;

  /// 현재 사용자 ID 설정 (로그인 시 호출)
  void setCurrentUserId(String? userId);
}
