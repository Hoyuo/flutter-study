import '../models/models.dart';

/// Abstract data source for remote weather data
abstract class WeatherRemoteDataSource {
  /// Gets current weather data for the specified coordinates
  ///
  /// Throws an exception if the request fails
  Future<WeatherResponseModel> getCurrentWeather({
    required double lat,
    required double lon,
    required String apiKey,
  });

  /// Gets current weather data for the specified city
  ///
  /// Throws an exception if the request fails
  Future<WeatherResponseModel> getWeatherByCity({
    required String cityName,
    required String apiKey,
  });
}
