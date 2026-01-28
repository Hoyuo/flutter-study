import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather_event.freezed.dart';

/// Weather 관련 이벤트
@freezed
sealed class WeatherEvent with _$WeatherEvent {
  /// 현재 위치 기반 날씨 조회
  const factory WeatherEvent.fetchCurrentWeather({
    required double latitude,
    required double longitude,
  }) = FetchCurrentWeather;

  /// 날씨 정보 새로고침
  const factory WeatherEvent.refreshWeather() = RefreshWeather;

  /// 날씨 정보 초기화
  const factory WeatherEvent.clearWeather() = ClearWeather;
}
