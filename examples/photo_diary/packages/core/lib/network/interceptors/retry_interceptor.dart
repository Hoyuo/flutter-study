import 'dart:math';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// Interceptor for retrying failed requests with exponential backoff
///
/// Retries requests that fail due to network issues or server errors (5xx).
/// Uses exponential backoff with jitter to prevent thundering herd.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    this.maxRetries = 3,
    this.initialDelayMs = 1000,
    this.maxDelayMs = 10000,
    this.retryEvaluator,
    Logger? logger,
  })  : assert(maxRetries >= 0, 'maxRetries must be >= 0'),
        assert(initialDelayMs > 0, 'initialDelayMs must be > 0'),
        assert(maxDelayMs >= initialDelayMs,
            'maxDelayMs must be >= initialDelayMs'),
        _logger = logger ?? Logger();

  /// Maximum number of retry attempts
  final int maxRetries;

  /// Initial delay in milliseconds before first retry
  final int initialDelayMs;

  /// Maximum delay in milliseconds between retries
  final int maxDelayMs;

  /// Custom function to determine if a request should be retried
  /// Returns true if the request should be retried
  final bool Function(DioException error)? retryEvaluator;

  final Logger _logger;
  final _random = Random();

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final shouldRetry = retryEvaluator?.call(err) ?? _shouldRetryRequest(err);

    if (!shouldRetry) {
      return handler.next(err);
    }

    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;

    if (retryCount >= maxRetries) {
      _logger.w(
        'Max retries ($maxRetries) reached for ${err.requestOptions.uri}',
      );
      return handler.next(err);
    }

    final delay = _calculateDelay(retryCount);
    _logger.i(
      'Retrying request (attempt ${retryCount + 1}/$maxRetries) '
      'after ${delay}ms: ${err.requestOptions.uri}',
    );

    await Future.delayed(Duration(milliseconds: delay));

    try {
      final dio = Dio();
      // Copy all interceptors except this one to avoid infinite recursion
      dio.interceptors.addAll(
        err.requestOptions.extra['_dio_interceptors'] as List<Interceptor>? ??
            [],
      );

      final response = await dio.fetch<dynamic>(
        err.requestOptions.copyWith(
          extra: {
            ...err.requestOptions.extra,
            'retryCount': retryCount + 1,
          },
        ),
      );

      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Determines if a request should be retried based on the error
  bool _shouldRetryRequest(DioException error) {
    // Retry on network errors
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }

    // Retry on 5xx server errors
    final statusCode = error.response?.statusCode;
    if (statusCode != null && statusCode >= 500 && statusCode < 600) {
      return true;
    }

    // Retry on 429 Too Many Requests
    if (statusCode == 429) {
      return true;
    }

    // Don't retry on other errors (4xx client errors, etc.)
    return false;
  }

  /// Calculates delay with exponential backoff and jitter
  int _calculateDelay(int retryCount) {
    // Exponential backoff: delay = initialDelay * 2^retryCount
    final exponentialDelay = initialDelayMs * pow(2, retryCount);

    // Cap at max delay
    final cappedDelay = min(exponentialDelay, maxDelayMs.toDouble());

    // Add jitter (random 0-50% of delay) to prevent thundering herd
    final jitter = _random.nextDouble() * 0.5 * cappedDelay;

    return (cappedDelay + jitter).toInt();
  }
}
