/// 크래시 리포팅 서비스 인터페이스
library;

/// 크래시 리포팅 서비스 인터페이스
///
/// Firebase Crashlytics 등의 크래시 리포팅 도구와 통합하여
/// 앱의 비정상 종료 및 에러를 추적합니다.
abstract class CrashlyticsService {
  /// 크래시 리포팅 활성화/비활성화
  ///
  /// [enabled] 활성화 여부
  Future<void> setCrashlyticsCollectionEnabled(bool enabled);

  /// 사용자 ID 설정
  ///
  /// 크래시 리포트에 사용자 정보를 포함시켜
  /// 특정 사용자에게 발생한 문제를 추적할 수 있습니다.
  ///
  /// [identifier] 사용자 고유 식별자
  Future<void> setUserIdentifier(String identifier);

  /// 커스텀 키 설정
  ///
  /// 크래시 리포트에 추가 컨텍스트를 제공합니다.
  ///
  /// [key] 키 이름
  /// [value] 키 값 (String, int, bool, double 등)
  Future<void> setCustomKey(String key, dynamic value);

  /// 비치명적 에러 기록
  ///
  /// 앱이 종료되지 않았지만 기록해야 할 에러를 리포팅합니다.
  ///
  /// [exception] 예외 객체
  /// [stackTrace] 스택 트레이스
  /// [reason] 에러 발생 이유 (선택사항)
  /// [fatal] 치명적 에러 여부 (기본값: false)
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  });

  /// 로그 메시지 기록
  ///
  /// 크래시 발생 시 컨텍스트를 파악하기 위한 로그를 기록합니다.
  ///
  /// [message] 로그 메시지
  Future<void> log(String message);
}
