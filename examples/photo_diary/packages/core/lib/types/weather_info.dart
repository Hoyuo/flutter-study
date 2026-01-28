import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather_info.freezed.dart';
part 'weather_info.g.dart';

/// Weather information for a diary entry
@freezed
class WeatherInfo with _$WeatherInfo {
  const factory WeatherInfo({
    required String condition,
    required double temperature,
    required String iconUrl,
    @Default(null) double? humidity,
  }) = _WeatherInfo;

  factory WeatherInfo.fromJson(Map<String, dynamic> json) =>
      _$WeatherInfoFromJson(json);
}
