import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// Base failure class for error handling
@freezed
sealed class Failure with _$Failure {
  const factory Failure.network({
    required String message,
    @Default(null) Exception? exception,
  }) = NetworkFailure;

  const factory Failure.server({
    required String message,
    @Default(null) int? statusCode,
    @Default(null) String? errorCode,
  }) = ServerFailure;

  const factory Failure.auth({
    required String message,
    @Default(null) String? errorCode,
  }) = AuthFailure;

  const factory Failure.cache({
    required String message,
    @Default(null) Exception? exception,
  }) = CacheFailure;

  const factory Failure.unknown({
    required String message,
    @Default(null) dynamic error,
  }) = UnknownFailure;
}
