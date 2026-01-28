import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

import '../entities/entities.dart';

/// Repository interface for weather operations
abstract class WeatherRepository {
  /// Gets current weather for the specified coordinates
  ///
  /// Returns [Weather] on success, [Failure] on error
  Future<Either<Failure, Weather>> getCurrentWeather({
    required double lat,
    required double lon,
  });

  /// Gets current weather for the specified city name
  ///
  /// Returns [Weather] on success, [Failure] on error
  Future<Either<Failure, Weather>> getWeatherByCity({
    required String cityName,
  });
}
