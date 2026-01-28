import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather.freezed.dart';
part 'weather.g.dart';

/// Weather entity representing current weather information
@freezed
class Weather with _$Weather {
  const factory Weather({
    /// Weather condition (e.g., 'Clear', 'Clouds', 'Rain')
    required String condition,

    /// Detailed description of the weather
    required String description,

    /// Temperature in Celsius
    required double temperature,

    /// Humidity percentage
    required int humidity,

    /// Weather icon code from the API
    required String iconCode,

    /// Full URL to the weather icon
    required String iconUrl,

    /// Name of the city
    required String cityName,

    /// Timestamp when the weather data was fetched
    required DateTime timestamp,
  }) = _Weather;

  factory Weather.fromJson(Map<String, dynamic> json) =>
      _$WeatherFromJson(json);
}
