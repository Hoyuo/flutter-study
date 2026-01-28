import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../error/failure.dart';

/// Interceptor for handling and transforming errors
///
/// Converts DioException to application-specific Failure types
/// and logs errors for debugging.
class ErrorInterceptor extends Interceptor {
  ErrorInterceptor({
    Logger? logger,
  }) : _logger = logger ?? Logger();

  final Logger _logger;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final failure = _mapDioExceptionToFailure(err);
    _logError(err, failure);

    // Pass the original error along with the failure in extra data
    final enhancedError = err.copyWith(
      error: failure,
    );

    handler.next(enhancedError);
  }

  Failure _mapDioExceptionToFailure(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Failure.network(
          message: 'Connection timeout. Please check your internet connection.',
          exception: error,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = _extractErrorMessage(error.response?.data);

        if (statusCode == 401 || statusCode == 403) {
          return Failure.auth(
            message: message ?? 'Authentication failed',
            errorCode: statusCode.toString(),
          );
        }

        return Failure.server(
          message: message ?? 'Server error occurred',
          statusCode: statusCode,
          errorCode: _extractErrorCode(error.response?.data),
        );

      case DioExceptionType.cancel:
        return const Failure.network(
          message: 'Request cancelled',
        );

      case DioExceptionType.connectionError:
        return Failure.network(
          message: 'No internet connection',
          exception: error,
        );

      case DioExceptionType.badCertificate:
        return Failure.network(
          message: 'Certificate verification failed',
          exception: error,
        );

      case DioExceptionType.unknown:
        return Failure.unknown(
          message: error.message ?? 'An unexpected error occurred',
          error: error,
        );
    }
  }

  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;

    if (data is Map<String, dynamic>) {
      // Try common error message fields
      return data['message'] as String? ??
          data['error'] as String? ??
          data['detail'] as String? ??
          data['msg'] as String?;
    }

    if (data is String) {
      return data;
    }

    return null;
  }

  String? _extractErrorCode(dynamic data) {
    if (data == null) return null;

    if (data is Map<String, dynamic>) {
      return data['code'] as String? ??
          data['errorCode'] as String? ??
          data['error_code'] as String?;
    }

    return null;
  }

  void _logError(DioException error, Failure failure) {
    // 프로덕션에서는 민감한 정보 로깅 비활성화
    if (kReleaseMode) {
      // 프로덕션에서는 에러 타입만 로깅 (민감한 정보 제외)
      _logger.e('HTTP Error: ${error.type}');
      return;
    }

    _logger.e(
      'HTTP Error',
      error: error,
      stackTrace: error.stackTrace,
    );

    _logger.d(
      'Request: ${error.requestOptions.method} ${error.requestOptions.uri}',
    );

    if (error.response != null) {
      _logger.d(
        'Response: ${error.response?.statusCode} - ${error.response?.data}',
      );
    }

    _logger.d('Mapped to: $failure');
  }
}
