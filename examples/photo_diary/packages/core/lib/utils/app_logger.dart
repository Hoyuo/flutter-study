import 'package:logger/logger.dart';

/// 앱 전역 로거 유틸리티
class AppLogger {
  AppLogger._();

  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, // 스택 트레이스 라인 수
      errorMethodCount: 8, // 에러 스택 트레이스 라인 수
      lineLength: 120, // 콘솔 폭
      colors: true, // 컬러 출력 사용
      printEmojis: true, // 이모지 사용
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart, // 시간 포맷
    ),
  );

  /// 디버그 로그
  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// 정보 로그
  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// 경고 로그
  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// 에러 로그
  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// 심각한 에러 로그
  static void wtf(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}

/// Bloc 옵저버와 통합 가능한 커스텀 로거
///
/// 사용 예시:
/// ```dart
/// class AppBlocObserver extends BlocObserver {
///   @override
///   void onEvent(Bloc bloc, Object? event) {
///     super.onEvent(bloc, event);
///     AppLogger.d('${bloc.runtimeType} Event: $event');
///   }
///
///   @override
///   void onChange(BlocBase bloc, Change change) {
///     super.onChange(bloc, change);
///     AppLogger.d('${bloc.runtimeType} Change: $change');
///   }
///
///   @override
///   void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
///     super.onError(bloc, error, stackTrace);
///     AppLogger.e('${bloc.runtimeType} Error', error, stackTrace);
///   }
/// }
/// ```
