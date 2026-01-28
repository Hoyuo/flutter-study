/// Firebase Analytics 구현체
library;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:injectable/injectable.dart';

import 'analytics_service.dart';

/// Firebase Analytics 서비스 구현체
///
/// [AnalyticsService] 인터페이스의 Firebase 기반 구현입니다.
@LazySingleton(as: AnalyticsService)
class FirebaseAnalyticsServiceImpl implements AnalyticsService {
  final FirebaseAnalytics _analytics;

  /// FirebaseAnalyticsServiceImpl 생성자
  FirebaseAnalyticsServiceImpl() : _analytics = FirebaseAnalytics.instance;

  @override
  Future<void> logEvent({
    required AnalyticsEventType type,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: type.name,
        parameters: parameters?.cast<String, Object>(),
      );
    } catch (e) {
      // 분석 실패는 앱 동작에 영향을 주지 않도록 조용히 처리
      // 프로덕션 환경에서는 로깅만 수행
    }
  }

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
    } catch (e) {
      // 분석 실패는 앱 동작에 영향을 주지 않도록 조용히 처리
    }
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(
        name: name,
        value: value,
      );
    } catch (e) {
      // 분석 실패는 앱 동작에 영향을 주지 않도록 조용히 처리
    }
  }

  @override
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      // 분석 실패는 앱 동작에 영향을 주지 않도록 조용히 처리
    }
  }
}
