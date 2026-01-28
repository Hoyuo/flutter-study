/// Firebase Crashlytics 구현체
library;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:injectable/injectable.dart';

import 'crashlytics_service.dart';

/// Firebase Crashlytics 서비스 구현체
///
/// [CrashlyticsService] 인터페이스의 Firebase 기반 구현입니다.
@LazySingleton(as: CrashlyticsService)
class FirebaseCrashlyticsServiceImpl implements CrashlyticsService {
  final FirebaseCrashlytics _crashlytics;

  /// FirebaseCrashlyticsServiceImpl 생성자
  FirebaseCrashlyticsServiceImpl()
      : _crashlytics = FirebaseCrashlytics.instance;

  @override
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    try {
      await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
    } catch (e) {
      // Crashlytics 설정 실패는 조용히 처리
    }
  }

  @override
  Future<void> setUserIdentifier(String identifier) async {
    try {
      await _crashlytics.setUserIdentifier(identifier);
    } catch (e) {
      // 사용자 식별자 설정 실패는 조용히 처리
    }
  }

  @override
  Future<void> setCustomKey(String key, dynamic value) async {
    try {
      await _crashlytics.setCustomKey(key, value as Object);
    } catch (e) {
      // 커스텀 키 설정 실패는 조용히 처리
    }
  }

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    try {
      await _crashlytics.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    } catch (e) {
      // 에러 기록 실패는 조용히 처리
    }
  }

  @override
  Future<void> log(String message) async {
    try {
      await _crashlytics.log(message);
    } catch (e) {
      // 로그 기록 실패는 조용히 처리
    }
  }
}
