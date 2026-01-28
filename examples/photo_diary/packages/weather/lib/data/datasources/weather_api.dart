import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/models.dart';

part 'weather_api.g.dart';

/// Retrofit API client for OpenWeatherMap
@RestApi(baseUrl: 'https://api.openweathermap.org/data/2.5')
abstract class WeatherApi {
  factory WeatherApi(Dio dio, {String baseUrl}) = _WeatherApi;

  /// Gets current weather by coordinates
  @GET('/weather')
  Future<WeatherResponseModel> getCurrentWeather({
    @Query('lat') required double lat,
    @Query('lon') required double lon,
    @Query('appid') required String apiKey,
    @Query('units') String units = 'metric',
  });

  /// Gets current weather by city name
  @GET('/weather')
  Future<WeatherResponseModel> getWeatherByCity({
    @Query('q') required String cityName,
    @Query('appid') required String apiKey,
    @Query('units') String units = 'metric',
  });
}
