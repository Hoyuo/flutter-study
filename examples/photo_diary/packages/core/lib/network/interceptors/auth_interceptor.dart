import 'package:dio/dio.dart';

/// Interceptor for handling authentication
///
/// Automatically adds authentication token to requests
/// and handles 401 Unauthorized responses.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokenProvider,
    this.onUnauthorized,
  });

  /// Function that provides the authentication token
  final Future<String?> Function() tokenProvider;

  /// Callback for handling unauthorized responses
  final Future<void> Function()? onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await tokenProvider();

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Token is invalid or expired
      await onUnauthorized?.call();
    }

    handler.next(err);
  }
}
