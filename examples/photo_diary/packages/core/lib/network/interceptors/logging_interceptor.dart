import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Interceptor for logging HTTP requests and responses
///
/// Provides detailed logging of HTTP traffic with pretty formatting.
/// Alternative to pretty_dio_logger package with more control.
class LoggingInterceptor extends Interceptor {
  LoggingInterceptor({
    this.requestHeader = true,
    this.requestBody = true,
    this.responseHeader = false,
    this.responseBody = true,
    this.error = true,
    this.maxWidth = 90,
    Logger? logger,
  }) : _logger = logger ?? Logger();

  /// Log request headers
  final bool requestHeader;

  /// Log request body
  final bool requestBody;

  /// Log response headers
  final bool responseHeader;

  /// Log response body
  final bool responseBody;

  /// Log errors
  final bool error;

  /// Maximum width for log lines
  final int maxWidth;

  final Logger _logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 프로덕션에서는 민감한 정보 로깅 비활성화
    if (kReleaseMode) {
      handler.next(options);
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln(
        '╔═══════════════════════════════════════════════════════════════');
    buffer.writeln('║ REQUEST');
    buffer.writeln(
        '╠═══════════════════════════════════════════════════════════════');
    buffer.writeln('║ ${options.method} ${options.uri}');

    if (requestHeader) {
      buffer.writeln(
          '╟───────────────────────────────────────────────────────────────');
      buffer.writeln('║ Headers:');
      options.headers.forEach((key, value) {
        // 민감한 헤더는 마스킹
        final maskedValue = _shouldMaskHeader(key) ? '***' : value;
        buffer.writeln('║   $key: $maskedValue');
      });
    }

    if (requestBody && options.data != null) {
      buffer.writeln(
          '╟───────────────────────────────────────────────────────────────');
      buffer.writeln('║ Body:');
      _logData(buffer, options.data);
    }

    buffer.writeln(
        '╚═══════════════════════════════════════════════════════════════');

    _logger.d(buffer.toString());
    handler.next(options);
  }

  /// 민감한 헤더인지 확인
  bool _shouldMaskHeader(String key) {
    final lowerKey = key.toLowerCase();
    return lowerKey == 'authorization' ||
        lowerKey == 'cookie' ||
        lowerKey == 'x-api-key' ||
        lowerKey == 'x-auth-token';
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    // 프로덕션에서는 민감한 정보 로깅 비활성화
    if (kReleaseMode) {
      handler.next(response);
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln(
        '╔═══════════════════════════════════════════════════════════════');
    buffer.writeln('║ RESPONSE');
    buffer.writeln(
        '╠═══════════════════════════════════════════════════════════════');
    buffer.writeln('║ ${response.statusCode} ${response.statusMessage}');
    buffer.writeln(
        '║ ${response.requestOptions.method} ${response.requestOptions.uri}');

    if (responseHeader) {
      buffer.writeln(
          '╟───────────────────────────────────────────────────────────────');
      buffer.writeln('║ Headers:');
      response.headers.map.forEach((key, value) {
        buffer.writeln('║   $key: ${value.join(', ')}');
      });
    }

    if (responseBody && response.data != null) {
      buffer.writeln(
          '╟───────────────────────────────────────────────────────────────');
      buffer.writeln('║ Body:');
      _logData(buffer, response.data);
    }

    buffer.writeln(
        '╚═══════════════════════════════════════════════════════════════');

    _logger.d(buffer.toString());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 프로덕션에서는 민감한 정보 로깅 비활성화
    if (kReleaseMode || !error) {
      handler.next(err);
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln(
        '╔═══════════════════════════════════════════════════════════════');
    buffer.writeln('║ ERROR');
    buffer.writeln(
        '╠═══════════════════════════════════════════════════════════════');
    buffer.writeln('║ ${err.requestOptions.method} ${err.requestOptions.uri}');
    buffer.writeln('║ ${err.type}');
    buffer.writeln('║ ${err.message}');

    if (err.response != null) {
      buffer.writeln(
          '╟───────────────────────────────────────────────────────────────');
      buffer.writeln('║ Response:');
      buffer.writeln('║   Status: ${err.response?.statusCode}');
      if (err.response?.data != null) {
        buffer.writeln('║   Body:');
        _logData(buffer, err.response?.data);
      }
    }

    buffer.writeln(
        '╚═══════════════════════════════════════════════════════════════');

    _logger.e(buffer.toString(), error: err, stackTrace: err.stackTrace);
    handler.next(err);
  }

  void _logData(StringBuffer buffer, dynamic data) {
    try {
      final prettyString = _prettyPrintJson(data);
      final lines = prettyString.split('\n');

      for (final line in lines) {
        if (line.length <= maxWidth) {
          buffer.writeln('║   $line');
        } else {
          // Wrap long lines
          var remaining = line;
          while (remaining.length > maxWidth) {
            buffer.writeln('║   ${remaining.substring(0, maxWidth)}');
            remaining = remaining.substring(maxWidth);
          }
          if (remaining.isNotEmpty) {
            buffer.writeln('║   $remaining');
          }
        }
      }
    } catch (e) {
      buffer.writeln('║   $data');
    }
  }

  String _prettyPrintJson(dynamic data) {
    if (data is String) {
      // Try to parse as JSON
      try {
        final decoded = jsonDecode(data);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      } catch (_) {
        return data;
      }
    } else if (data is Map || data is List) {
      return const JsonEncoder.withIndent('  ').convert(data);
    } else {
      return data.toString();
    }
  }
}
