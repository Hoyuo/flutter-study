import 'package:dio/dio.dart';

import '../models/models.dart';
import 'weather_api.dart';
import 'weather_remote_datasource.dart';

/// Implementation of [WeatherRemoteDataSource] using OpenWeatherMap API
class OpenWeatherMapRemoteDataSourceImpl implements WeatherRemoteDataSource {
  final WeatherApi _api;

  OpenWeatherMapRemoteDataSourceImpl(Dio dio) : _api = WeatherApi(dio);

  @override
  Future<WeatherResponseModel> getCurrentWeather({
    required double lat,
    required double lon,
    required String apiKey,
  }) async {
    try {
      return await _api.getCurrentWeather(
        lat: lat,
        lon: lon,
        apiKey: apiKey,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<WeatherResponseModel> getWeatherByCity({
    required String cityName,
    required String apiKey,
  }) async {
    try {
      return await _api.getWeatherByCity(
        cityName: cityName,
        apiKey: apiKey,
      );
    } catch (e) {
      rethrow;
    }
  }
}
