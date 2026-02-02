import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

/// Base failure class for error handling
@freezed
abstract class Failure with _$Failure {
  const factory Failure.database({
    required String message,
    Exception? exception,
  }) = DatabaseFailure;

  const factory Failure.validation({
    required String message,
    String? field,
  }) = ValidationFailure;

  const factory Failure.notFound({
    required String message,
    String? entityId,
  }) = NotFoundFailure;

  const factory Failure.cache({
    required String message,
    Exception? exception,
  }) = CacheFailure;

  const factory Failure.unknown({
    required String message,
    dynamic error,
  }) = UnknownFailure;
}
