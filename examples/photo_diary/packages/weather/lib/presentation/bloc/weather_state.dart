import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:core/core.dart';

import '../../domain/entities/entities.dart';

part 'weather_state.freezed.dart';

/// Weather 상태
@freezed
abstract class WeatherState with _$WeatherState {
  const factory WeatherState({
    /// 현재 날씨 정보
    Weather? weather,

    /// 로딩 상태
    @Default(false) bool isLoading,

    /// 에러 정보
    Failure? failure,

    /// 마지막 업데이트 시간
    DateTime? lastUpdated,
  }) = _WeatherState;
}
