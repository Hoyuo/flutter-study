/// GoRouter용 Analytics 옵저버
library;

import 'package:core/services/services.dart';
import 'package:flutter/material.dart';

/// GoRouter용 Analytics 옵저버
///
/// 화면 전환을 감지하여 자동으로 Analytics에 화면 조회 이벤트를 기록합니다.
class AnalyticsRouteObserver extends NavigatorObserver {
  final AnalyticsService _analyticsService;

  /// AnalyticsRouteObserver 생성자
  ///
  /// [_analyticsService] Analytics 서비스 인스턴스
  AnalyticsRouteObserver(this._analyticsService);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logScreenView(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _logScreenView(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _logScreenView(newRoute);
    }
  }

  /// 화면 조회 이벤트 기록
  void _logScreenView(Route<dynamic> route) {
    final screenName = route.settings.name;
    if (screenName != null && screenName.isNotEmpty) {
      _analyticsService.logScreenView(
        screenName: screenName,
        screenClass: route.runtimeType.toString(),
      );
    }
  }
}
