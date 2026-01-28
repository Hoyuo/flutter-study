import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/entities.dart';
import '../../domain/usecases/usecases.dart';
import 'settings_event.dart';
import 'settings_state.dart';

/// 설정 BLoC
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetSettingsUseCase _getSettingsUseCase;
  final UpdateSettingsUseCase _updateSettingsUseCase;

  SettingsBloc({
    required GetSettingsUseCase getSettingsUseCase,
    required UpdateSettingsUseCase updateSettingsUseCase,
  })  : _getSettingsUseCase = getSettingsUseCase,
        _updateSettingsUseCase = updateSettingsUseCase,
        super(SettingsState.initial()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateThemeMode>(_onUpdateThemeMode);
    on<UpdateLocale>(_onUpdateLocale);
    on<ToggleBiometricAuth>(_onToggleBiometricAuth);
    on<TogglePushNotification>(_onTogglePushNotification);
    on<ResetSettings>(_onResetSettings);
  }

  /// 설정 로드
  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, failure: null));

    final result = await _getSettingsUseCase(const NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        failure: failure,
      )),
      (settings) => emit(state.copyWith(
        isLoading: false,
        settings: settings,
        failure: null,
      )),
    );
  }

  /// 테마 모드 업데이트
  Future<void> _onUpdateThemeMode(
    UpdateThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    final currentSettings = state.settings;
    if (currentSettings == null) return;

    emit(state.copyWith(isSaving: true, failure: null));

    final updatedSettings = currentSettings.copyWith(
      themeMode: event.themeMode,
    );

    final result = await _updateSettingsUseCase(
      UpdateSettingsParams(settings: updatedSettings),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isSaving: false,
        failure: failure,
      )),
      (settings) => emit(state.copyWith(
        isSaving: false,
        settings: settings,
        failure: null,
      )),
    );
  }

  /// 언어 업데이트
  Future<void> _onUpdateLocale(
    UpdateLocale event,
    Emitter<SettingsState> emit,
  ) async {
    final currentSettings = state.settings;
    if (currentSettings == null) return;

    emit(state.copyWith(isSaving: true, failure: null));

    final updatedSettings = currentSettings.copyWith(
      languageCode: event.locale.languageCode,
    );

    final result = await _updateSettingsUseCase(
      UpdateSettingsParams(settings: updatedSettings),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isSaving: false,
        failure: failure,
      )),
      (settings) => emit(state.copyWith(
        isSaving: false,
        settings: settings,
        failure: null,
      )),
    );
  }

  /// 생체인증 토글
  Future<void> _onToggleBiometricAuth(
    ToggleBiometricAuth event,
    Emitter<SettingsState> emit,
  ) async {
    final currentSettings = state.settings;
    if (currentSettings == null) return;

    emit(state.copyWith(isSaving: true, failure: null));

    final updatedSettings = currentSettings.copyWith(
      biometricLockEnabled: event.enabled,
    );

    final result = await _updateSettingsUseCase(
      UpdateSettingsParams(settings: updatedSettings),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isSaving: false,
        failure: failure,
      )),
      (settings) => emit(state.copyWith(
        isSaving: false,
        settings: settings,
        failure: null,
      )),
    );
  }

  /// 푸시 알림 토글
  Future<void> _onTogglePushNotification(
    TogglePushNotification event,
    Emitter<SettingsState> emit,
  ) async {
    final currentSettings = state.settings;
    if (currentSettings == null) return;

    emit(state.copyWith(isSaving: true, failure: null));

    final updatedSettings = currentSettings.copyWith(
      notificationsEnabled: event.enabled,
    );

    final result = await _updateSettingsUseCase(
      UpdateSettingsParams(settings: updatedSettings),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isSaving: false,
        failure: failure,
      )),
      (settings) => emit(state.copyWith(
        isSaving: false,
        settings: settings,
        failure: null,
      )),
    );
  }

  /// 설정 초기화
  Future<void> _onResetSettings(
    ResetSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isSaving: true, failure: null));

    // 기본 설정으로 초기화
    const defaultSettings = AppSettings();

    final result = await _updateSettingsUseCase(
      UpdateSettingsParams(settings: defaultSettings),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isSaving: false,
        failure: failure,
      )),
      (settings) => emit(state.copyWith(
        isSaving: false,
        settings: settings,
        failure: null,
      )),
    );
  }
}
