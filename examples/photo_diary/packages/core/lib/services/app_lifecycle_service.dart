/// 앱 생명주기 상태
enum AppLifecycleState {
  /// 포그라운드 - 앱이 활성화되어 사용자와 상호작용 중
  resumed,

  /// 전환 중 - 앱이 일시적으로 비활성 상태 (전화, 시스템 팝업 등)
  inactive,

  /// 백그라운드 - 앱이 백그라운드에 있음
  paused,

  /// 종료 중 - 앱이 완전히 종료되기 직전
  detached,

  /// iOS 숨김 상태 - 앱이 시스템에 의해 숨겨진 상태
  hidden,
}

/// 앱 생명주기 이벤트 리스너
///
/// 앱 상태가 변경될 때 호출되는 콜백 함수
typedef AppLifecycleListener = void Function(AppLifecycleState state);

/// 앱 생명주기 서비스 인터페이스
///
/// 앱의 생명주기 상태를 추적하고 상태 변경 이벤트를 전달합니다.
/// WidgetsBindingObserver를 통해 Flutter 프레임워크의 생명주기 이벤트를 감지합니다.
abstract class AppLifecycleService {
  /// 현재 앱 생명주기 상태
  AppLifecycleState get currentState;

  /// 앱 생명주기 상태 변경 스트림
  ///
  /// 이 스트림을 구독하여 상태 변경을 실시간으로 감지할 수 있습니다.
  Stream<AppLifecycleState> get stateChanges;

  /// 생명주기 상태 변경 리스너 등록
  ///
  /// [listener]가 이미 등록되어 있어도 중복으로 추가됩니다.
  void addListener(AppLifecycleListener listener);

  /// 생명주기 상태 변경 리스너 해제
  ///
  /// [listener]가 여러 번 등록되어 있으면 첫 번째 것만 제거됩니다.
  void removeListener(AppLifecycleListener listener);

  /// 서비스 정리
  ///
  /// 모든 리스너를 제거하고 스트림을 닫습니다.
  /// 앱 종료 시 호출되어야 합니다.
  void dispose();
}
