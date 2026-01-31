import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/entities.dart';
import '../../domain/usecases/usecases.dart';
import 'settings_event.dart';
import 'settings_state.dart';
import 'settings_ui_effect.dart';

/// 설정 BLoC
///
/// BlocUiEffectMixin을 사용하여 일회성 UI 이벤트를 처리합니다.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState>
    with BlocUiEffectMixin<SettingsUiEffect, SettingsState> {
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
      (failure) {
        emit(state.copyWith(
          isLoading: false,
          failure: failure,
        ));
        emitUiEffect(SettingsUiEffect.showError(_getFailureMessage(failure)));
      },
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
      (failure) {
        emit(state.copyWith(
          isSaving: false,
          failure: failure,
        ));
        emitUiEffect(SettingsUiEffect.showError(_getFailureMessage(failure)));
      },
      (settings) {
        emit(state.copyWith(
          isSaving: false,
          settings: settings,
          failure: null,
        ));
        emitUiEffect(const SettingsUiEffect.showSuccess('테마가 변경되었습니다'));
      },
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
      (failure) {
        emit(state.copyWith(
          isSaving: false,
          failure: failure,
        ));
        emitUiEffect(SettingsUiEffect.showError(_getFailureMessage(failure)));
      },
      (settings) {
        emit(state.copyWith(
          isSaving: false,
          settings: settings,
          failure: null,
        ));
        emitUiEffect(const SettingsUiEffect.showSuccess('언어가 변경되었습니다'));
      },
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
      (failure) {
        emit(state.copyWith(
          isSaving: false,
          failure: failure,
        ));
        emitUiEffect(SettingsUiEffect.showError(_getFailureMessage(failure)));
      },
      (settings) {
        emit(state.copyWith(
          isSaving: false,
          settings: settings,
          failure: null,
        ));
        emitUiEffect(SettingsUiEffect.showSuccess(
          event.enabled ? '생체인증이 활성화되었습니다' : '생체인증이 비활성화되었습니다',
        ));
      },
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
      (failure) {
        emit(state.copyWith(
          isSaving: false,
          failure: failure,
        ));
        emitUiEffect(SettingsUiEffect.showError(_getFailureMessage(failure)));
      },
      (settings) {
        emit(state.copyWith(
          isSaving: false,
          settings: settings,
          failure: null,
        ));
        emitUiEffect(SettingsUiEffect.showSuccess(
          event.enabled ? '푸시 알림이 활성화되었습니다' : '푸시 알림이 비활성화되었습니다',
        ));
      },
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
      (failure) {
        emit(state.copyWith(
          isSaving: false,
          failure: failure,
        ));
        emitUiEffect(SettingsUiEffect.showError(_getFailureMessage(failure)));
      },
      (settings) {
        emit(state.copyWith(
          isSaving: false,
          settings: settings,
          failure: null,
        ));
        emitUiEffect(const SettingsUiEffect.showSuccess('설정이 초기화되었습니다'));
      },
    );
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
