import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/entities.dart';

part 'weather_response_model.freezed.dart';
part 'weather_response_model.g.dart';

/// Weather response model from OpenWeatherMap API
@freezed
abstract class WeatherResponseModel with _$WeatherResponseModel {
  const WeatherResponseModel._();

  const factory WeatherResponseModel({
    /// List of weather conditions
    required List<WeatherCondition> weather,

    /// Main weather data (temperature, humidity, etc.)
    required MainWeatherData main,

    /// City name
    required String name,

    /// Timestamp (Unix, UTC)
    @JsonKey(name: 'dt') required int timestamp,
  }) = _WeatherResponseModel;

  factory WeatherResponseModel.fromJson(Map<String, dynamic> json) =>
      _$WeatherResponseModelFromJson(json);

  /// Converts the model to a domain entity
  Weather toEntity() {
    final weatherCondition = weather.first;
    return Weather(
      condition: weatherCondition.main,
      description: weatherCondition.description,
      temperature: main.temp,
      humidity: main.humidity,
      iconCode: weatherCondition.icon,
      iconUrl:
          'https://openweathermap.org/img/wn/${weatherCondition.icon}@2x.png',
      cityName: name,
      timestamp:
          DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true),
    );
  }
}

/// Weather condition data
@freezed
abstract class WeatherCondition with _$WeatherCondition {
  const factory WeatherCondition({
    /// Weather condition (e.g., 'Clear', 'Clouds', 'Rain')
    required String main,

    /// Detailed description
    required String description,

    /// Weather icon code
    required String icon,
  }) = _WeatherCondition;

  factory WeatherCondition.fromJson(Map<String, dynamic> json) =>
      _$WeatherConditionFromJson(json);
}

/// Main weather data (temperature, humidity, etc.)
@freezed
abstract class MainWeatherData with _$MainWeatherData {
  const factory MainWeatherData({
    /// Temperature in Celsius
    required double temp,

    /// Humidity percentage
    required int humidity,
  }) = _MainWeatherData;

  factory MainWeatherData.fromJson(Map<String, dynamic> json) =>
      _$MainWeatherDataFromJson(json);
}
