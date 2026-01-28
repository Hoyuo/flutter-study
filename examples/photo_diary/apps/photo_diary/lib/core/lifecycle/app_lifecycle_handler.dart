import 'package:core/core.dart';
import 'package:injectable/injectable.dart';

/// 앱 생명주기 핸들러
///
/// 앱 상태 변화에 따른 동작을 정의하고 실행합니다.
/// 포그라운드 복귀, 백그라운드 진입 등의 상황에서
/// 필요한 작업을 수행합니다.
@singleton
class AppLifecycleHandler {
  /// 생체인증 활성화 여부 저장 키
  static const String _biometricEnabledKey = 'biometric_enabled';

  // ignore: sort_constructors_first
  AppLifecycleHandler({
    required AppLifecycleService lifecycleService,
    required BiometricService biometricService,
    required AnalyticsService analyticsService,
    required SecureStorageService storageService,
  }) : _lifecycleService = lifecycleService,
       _biometricService = biometricService,
       _analyticsService = analyticsService,
       _storageService = storageService {
    _init();
  }

  final AppLifecycleService _lifecycleService;
  final BiometricService _biometricService;
  final AnalyticsService _analyticsService;
  final SecureStorageService _storageService;

  /// 핸들러 초기화
  ///
  /// 생명주기 리스너를 등록하여 상태 변경을 감지합니다.
  void _init() {
    _lifecycleService.addListener(_onStateChanged);
  }

  /// 앱 생명주기 상태 변경 콜백
  ///
  /// 각 상태에 따라 적절한 동작을 수행합니다:
  /// - resumed: 앱이 포그라운드로 복귀
  /// - paused: 앱이 백그라운드로 진입
  /// - inactive: 앱이 일시적으로 비활성 상태
  /// - detached: 앱이 종료 중
  /// - hidden: 앱이 숨김 상태 (iOS)
  void _onStateChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // 포그라운드 복귀
        // - 생체인증 체크 (설정된 경우)
        // - 데이터 새로고침
        // - 앱 재개 이벤트 로깅
        _onResumed();
        break;

      case AppLifecycleState.paused:
        // 백그라운드 진입
        // - 임시 데이터 저장
        // - 민감 정보 숨기기
        _onPaused();
        break;

      case AppLifecycleState.inactive:
        // 전환 중 (멀티태스킹 화면, 시스템 팝업 등)
        // 특별한 처리 없음
        break;

      case AppLifecycleState.detached:
        // 앱 종료 중
        // - 정리 작업 수행
        _onDetached();
        break;

      case AppLifecycleState.hidden:
        // iOS 숨김 상태
        // 특별한 처리 없음
        break;
    }
  }

  /// 포그라운드 복귀 처리
  ///
  /// 앱이 백그라운드에서 다시 활성화될 때 호출됩니다.
  Future<void> _onResumed() async {
    // 앱 재개 이벤트 로깅
    await _analyticsService.logEvent(
      type: AnalyticsEventType.appOpen,
      parameters: {'source': 'resume'},
    );

    // 생체인증 활성화 여부 확인
    final biometricEnabled = await _isBiometricEnabled();

    if (biometricEnabled) {
      // 생체인증 수행
      // TODO: 라우터를 통해 생체인증 화면으로 이동하거나
      // 현재 화면 위에 생체인증 다이얼로그 표시
      await _authenticateWithBiometric();
    }

    // TODO: 데이터 새로고침
    // - 서버와 동기화
    // - 로컬 데이터 업데이트
  }

  /// 백그라운드 진입 처리
  ///
  /// 앱이 백그라운드로 이동할 때 호출됩니다.
  Future<void> _onPaused() async {
    // TODO: 임시 데이터 저장
    // - 사용자가 작성 중인 일기 임시 저장
    // - 현재 화면 상태 저장

    // TODO: 민감 정보 숨기기
    // - 화면 스크린샷에 표시될 수 있는 민감한 정보 마스킹
    // - 생체인증 락 화면 표시 준비
  }

  /// 앱 종료 중 처리
  ///
  /// 앱이 완전히 종료되기 직전에 호출됩니다.
  void _onDetached() {
    // TODO: 정리 작업
    // - 임시 파일 삭제
    // - 리소스 해제
  }

  /// 생체인증 활성화 여부 확인
  ///
  /// 사용자가 설정에서 생체인증을 활성화했는지 확인합니다.
  Future<bool> _isBiometricEnabled() async {
    try {
      final value = await _storageService.read(key: _biometricEnabledKey);
      return value == 'true';
    } on Exception {
      // 저장소 읽기 실패 시 false 반환
      return false;
    }
  }

  /// 생체인증 수행
  ///
  /// 디바이스의 생체인증 기능을 사용하여 사용자 인증을 수행합니다.
  Future<void> _authenticateWithBiometric() async {
    try {
      // 생체인증 사용 가능 여부 확인
      final canAuthenticate = await _biometricService.isAvailable();

      if (!canAuthenticate) {
        // 생체인증 불가능한 경우
        // TODO: 대체 인증 방법 제공 (PIN, 패턴 등)
        return;
      }

      // 생체인증 수행
      final authenticated = await _biometricService.authenticate(
        localizedReason: '일기를 보려면 인증이 필요합니다',
      );

      if (!authenticated) {
        // 인증 실패 또는 취소
        // TODO: 앱 종료 또는 재시도 옵션 제공
      }
    } on Exception {
      // 생체인증 오류 발생
      // TODO: 오류 처리 및 대체 인증 방법 제공
    }
  }

  /// 핸들러 정리
  ///
  /// 생명주기 리스너를 제거합니다.
  @disposeMethod
  void dispose() {
    _lifecycleService.removeListener(_onStateChanged);
  }
}
