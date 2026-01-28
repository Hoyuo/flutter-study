import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

import '../entities/entities.dart';
import '../repositories/repositories.dart';

/// Use case for getting current weather information
class GetCurrentWeatherUseCase
    implements UseCase<Weather, GetCurrentWeatherParams> {
  final WeatherRepository _repository;

  const GetCurrentWeatherUseCase(this._repository);

  @override
  Future<Either<Failure, Weather>> call(GetCurrentWeatherParams params) {
    if (params.cityName != null) {
      return _repository.getWeatherByCity(cityName: params.cityName!);
    }

    if (params.lat != null && params.lon != null) {
      return _repository.getCurrentWeather(
        lat: params.lat!,
        lon: params.lon!,
      );
    }

    return Future.value(
      Left(
        const Failure.unknown(
          message: 'Either cityName or (lat, lon) must be provided',
        ),
      ),
    );
  }
}

/// Parameters for getting current weather
class GetCurrentWeatherParams {
  final double? lat;
  final double? lon;
  final String? cityName;

  const GetCurrentWeatherParams({
    this.lat,
    this.lon,
    this.cityName,
  });

  /// Creates params from coordinates
  const GetCurrentWeatherParams.fromCoordinates({
    required double lat,
    required double lon,
  })  : lat = lat,
        lon = lon,
        cityName = null;

  /// Creates params from city name
  const GetCurrentWeatherParams.fromCity({
    required String cityName,
  })  : cityName = cityName,
        lat = null,
        lon = null;
}
