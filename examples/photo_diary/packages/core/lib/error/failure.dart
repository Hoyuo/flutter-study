import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// Base failure class for error handling
@freezed
abstract class Failure with _$Failure {
  const factory Failure.network({
    required String message,
    Exception? exception,
  }) = NetworkFailure;

  const factory Failure.server({
    required String message,
    int? statusCode,
    String? errorCode,
  }) = ServerFailure;

  const factory Failure.auth({
    required String message,
    String? errorCode,
  }) = AuthFailure;

  const factory Failure.cache({
    required String message,
    Exception? exception,
  }) = CacheFailure;

  const factory Failure.unknown({
    required String message,
    dynamic error,
  }) = UnknownFailure;
}
