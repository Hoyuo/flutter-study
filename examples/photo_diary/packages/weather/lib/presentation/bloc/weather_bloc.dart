import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/usecases.dart';
import 'weather_event.dart';
import 'weather_state.dart';
import 'weather_ui_effect.dart';

export 'weather_event.dart';
export 'weather_state.dart';

/// Weather BLoC - 날씨 정보 관리
///
/// 위치 기반 날씨 조회, 새로고침, 초기화 기능 제공
/// BlocUiEffectMixin을 사용하여 일회성 UI 이벤트를 처리합니다.
class WeatherBloc extends Bloc<WeatherEvent, WeatherState>
    with BlocUiEffectMixin<WeatherUiEffect, WeatherState> {
  final GetCurrentWeatherUseCase _getCurrentWeatherUseCase;

  WeatherBloc({
    required GetCurrentWeatherUseCase getCurrentWeatherUseCase,
  })  : _getCurrentWeatherUseCase = getCurrentWeatherUseCase,
        super(const WeatherState()) {
    on<FetchCurrentWeather>(_onFetchCurrentWeather);
    on<RefreshWeather>(_onRefreshWeather);
    on<ClearWeather>(_onClearWeather);
  }

  /// 현재 위치 기반 날씨 조회
  Future<void> _onFetchCurrentWeather(
    FetchCurrentWeather event,
    Emitter<WeatherState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, failure: null));

    final params = GetCurrentWeatherParams.fromCoordinates(
      lat: event.latitude,
      lon: event.longitude,
    );

    final result = await _getCurrentWeatherUseCase(params);

    result.fold(
      (failure) {
        emit(state.copyWith(
          isLoading: false,
          failure: failure,
        ));
        emitUiEffect(WeatherUiEffect.showError(_getFailureMessage(failure)));
      },
      (weather) => emit(state.copyWith(
        isLoading: false,
        weather: weather,
        failure: null,
        lastUpdated: DateTime.now(),
      )),
    );
  }

  /// 날씨 정보 새로고침
  Future<void> _onRefreshWeather(
    RefreshWeather event,
    Emitter<WeatherState> emit,
  ) async {
    // 현재 날씨 정보가 있는 경우에만 새로고침
    final currentWeather = state.weather;
    if (currentWeather == null) return;

    emit(state.copyWith(isLoading: true, failure: null));

    // 이전에 사용한 좌표로 다시 조회
    // Note: 실제 구현에서는 마지막 좌표를 저장해두거나 재조회 로직 필요
    final params = GetCurrentWeatherParams.fromCity(
      cityName: currentWeather.cityName,
    );

    final result = await _getCurrentWeatherUseCase(params);

    result.fold(
      (failure) {
        emit(state.copyWith(
          isLoading: false,
          failure: failure,
        ));
        emitUiEffect(WeatherUiEffect.showError(_getFailureMessage(failure)));
      },
      (weather) => emit(state.copyWith(
        isLoading: false,
        weather: weather,
        failure: null,
        lastUpdated: DateTime.now(),
      )),
    );
  }

  /// 날씨 정보 초기화
  void _onClearWeather(
    ClearWeather event,
    Emitter<WeatherState> emit,
  ) {
    emit(const WeatherState());
  }

  /// Failure 객체를 사용자 친화적인 메시지로 변환
  String _getFailureMessage(Failure failure) {
    return switch (failure) {
      NetworkFailure(:final message) => '네트워크 오류: $message',
      ServerFailure(:final message) => '서버 오류: $message',
      AuthFailure(:final message) => '인증 오류: $message',
      CacheFailure(:final message) => '캐시 오류: $message',
      UnknownFailure(:final message) => '알 수 없는 오류: $message',
      _ => '오류가 발생했습니다',
    };
  }
}
