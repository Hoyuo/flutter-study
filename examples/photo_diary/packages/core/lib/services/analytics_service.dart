/// 분석 이벤트를 로깅하기 위한 서비스 인터페이스
library;

/// 분석 이벤트 타입
enum AnalyticsEventType {
  /// 인증 관련
  login,
  signUp,
  logout,

  /// 일기 관련
  createDiary,
  viewDiary,
  editDiary,
  deleteDiary,

  /// 검색
  search,

  /// 설정
  changeTheme,
  changeLanguage,
  toggleBiometric,

  /// 기타
  screenView,
  appOpen,
  share,
}

/// 분석 서비스 인터페이스
///
/// Firebase Analytics 등의 분석 도구와 통합하여
/// 사용자 행동을 추적하고 앱 사용 패턴을 분석합니다.
abstract class AnalyticsService {
  /// 이벤트 로깅
  ///
  /// [type] 이벤트 타입
  /// [parameters] 추가 파라미터 (선택사항)
  Future<void> logEvent({
    required AnalyticsEventType type,
    Map<String, dynamic>? parameters,
  });

  /// 화면 조회 로깅
  ///
  /// [screenName] 화면 이름
  /// [screenClass] 화면 클래스 이름 (선택사항)
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  });

  /// 사용자 속성 설정
  ///
  /// [name] 속성 이름
  /// [value] 속성 값
  Future<void> setUserProperty({
    required String name,
    required String? value,
  });

  /// 사용자 ID 설정
  ///
  /// [userId] 사용자 고유 식별자
  Future<void> setUserId(String? userId);
}
