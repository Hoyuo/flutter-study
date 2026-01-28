import 'dart:io';

import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/datasources.dart';

/// Implementation of [WeatherRepository]
class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherRemoteDataSource _remoteDataSource;
  final String _apiKey;

  WeatherRepositoryImpl({
    required WeatherRemoteDataSource remoteDataSource,
    required String apiKey,
  })  : _remoteDataSource = remoteDataSource,
        _apiKey = apiKey;

  @override
  Future<Either<Failure, Weather>> getCurrentWeather({
    required double lat,
    required double lon,
  }) async {
    return TaskEither.tryCatch(
      () async {
        final response = await _remoteDataSource.getCurrentWeather(
          lat: lat,
          lon: lon,
          apiKey: _apiKey,
        );
        return response.toEntity();
      },
      (error, stackTrace) => _handleError(error),
    ).run();
  }

  @override
  Future<Either<Failure, Weather>> getWeatherByCity({
    required String cityName,
  }) async {
    return TaskEither.tryCatch(
      () async {
        final response = await _remoteDataSource.getWeatherByCity(
          cityName: cityName,
          apiKey: _apiKey,
        );
        return response.toEntity();
      },
      (error, stackTrace) => _handleError(error),
    ).run();
  }

  /// Handles errors and converts them to [Failure] instances
  Failure _handleError(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return Failure.network(
          message: 'Connection timeout. Please check your internet connection.',
          exception: error,
        );
      }

      if (error.type == DioExceptionType.badResponse) {
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] as String? ??
            'Server error occurred';

        return Failure.server(
          message: message,
          statusCode: statusCode,
        );
      }

      return Failure.network(
        message: 'Network error occurred. Please try again.',
        exception: error,
      );
    }

    if (error is SocketException) {
      return Failure.network(
        message: 'No internet connection. Please check your network.',
        exception: error,
      );
    }

    return Failure.unknown(
      message: 'An unexpected error occurred',
      error: error,
    );
  }
}
