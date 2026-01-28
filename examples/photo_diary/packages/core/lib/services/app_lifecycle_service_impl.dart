import 'dart:async';

import 'package:core/services/app_lifecycle_service.dart';
import 'package:flutter/widgets.dart' as flutter;
import 'package:injectable/injectable.dart';

/// 앱 생명주기 서비스 구현체
///
/// WidgetsBindingObserver를 사용하여 Flutter 프레임워크의
/// 생명주기 이벤트를 감지하고 이를 앱 전체에 전파합니다.
@LazySingleton(as: AppLifecycleService)
class AppLifecycleServiceImpl
    with flutter.WidgetsBindingObserver
    implements AppLifecycleService {
  /// 상태 변경 브로드캐스트 컨트롤러
  final _stateController = StreamController<AppLifecycleState>.broadcast();

  /// 등록된 리스너 목록
  final List<AppLifecycleListener> _listeners = [];

  /// 현재 생명주기 상태
  AppLifecycleState _currentState = AppLifecycleState.resumed;

  /// 서비스 초기화
  ///
  /// WidgetsBinding에 옵저버를 등록하여 생명주기 이벤트를 수신합니다.
  // ignore: sort_constructors_first
  AppLifecycleServiceImpl() {
    flutter.WidgetsBinding.instance.addObserver(this);
  }

  @override
  AppLifecycleState get currentState => _currentState;

  @override
  Stream<AppLifecycleState> get stateChanges => _stateController.stream;

  /// 앱 생명주기 상태 변경 콜백
  ///
  /// Flutter 프레임워크가 앱 상태 변경을 감지하면 이 메서드가 호출됩니다.
  @override
  void didChangeAppLifecycleState(flutter.AppLifecycleState state) {
    final newState = _mapState(state);
    if (newState != _currentState) {
      _currentState = newState;

      // 스트림으로 상태 변경 전파
      _stateController.add(newState);

      // 등록된 모든 리스너에게 상태 변경 알림
      for (final listener in _listeners) {
        listener(newState);
      }
    }
  }

  /// Flutter의 AppLifecycleState를 앱의 AppLifecycleState로 변환
  ///
  /// Flutter 3.13+의 새로운 생명주기 상태(hidden)도 지원합니다.
  AppLifecycleState _mapState(flutter.AppLifecycleState state) {
    return switch (state) {
      flutter.AppLifecycleState.resumed => AppLifecycleState.resumed,
      flutter.AppLifecycleState.inactive => AppLifecycleState.inactive,
      flutter.AppLifecycleState.paused => AppLifecycleState.paused,
      flutter.AppLifecycleState.detached => AppLifecycleState.detached,
      flutter.AppLifecycleState.hidden => AppLifecycleState.hidden,
    };
  }

  @override
  void addListener(AppLifecycleListener listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(AppLifecycleListener listener) {
    _listeners.remove(listener);
  }

  /// 서비스 정리
  ///
  /// - WidgetsBinding에서 옵저버 제거
  /// - 스트림 컨트롤러 닫기
  /// - 모든 리스너 제거
  @override
  @disposeMethod
  void dispose() {
    flutter.WidgetsBinding.instance.removeObserver(this);
    _stateController.close();
    _listeners.clear();
  }
}
