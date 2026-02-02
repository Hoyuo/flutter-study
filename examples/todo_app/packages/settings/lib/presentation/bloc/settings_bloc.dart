import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/usecases/get_settings_usecase.dart';
import '../../domain/usecases/save_settings_usecase.dart';

part 'settings_bloc.freezed.dart';
part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState>
    with BlocUiEffectMixin<SettingsUiEffect, SettingsState> {
  final GetSettingsUseCase getSettingsUseCase;
  final SaveSettingsUseCase saveSettingsUseCase;

  SettingsBloc({
    required this.getSettingsUseCase,
    required this.saveSettingsUseCase,
  }) : super(const SettingsState()) {
    on<SettingsEventLoadSettings>(_onLoadSettings);
    on<SettingsEventUpdateTheme>(_onUpdateTheme);
    on<SettingsEventUpdateLanguage>(_onUpdateLanguage);
    on<SettingsEventToggleNotifications>(_onToggleNotifications);
  }

  Future<void> _onLoadSettings(
    SettingsEventLoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await getSettingsUseCase(NoParams());

    result.fold(
      (failure) {
        emit(state.copyWith(isLoading: false));
        emitUiEffect(SettingsUiEffect.showError(failure.message));
      },
      (settings) {
        emit(state.copyWith(
          settings: settings,
          isLoading: false,
        ));
      },
    );
  }

  Future<void> _onUpdateTheme(
    SettingsEventUpdateTheme event,
    Emitter<SettingsState> emit,
  ) async {
    final updatedSettings = state.settings.copyWith(themeMode: event.themeMode);
    await _saveSettings(updatedSettings, emit);
  }

  Future<void> _onUpdateLanguage(
    SettingsEventUpdateLanguage event,
    Emitter<SettingsState> emit,
  ) async {
    final updatedSettings = state.settings.copyWith(language: event.language);
    await _saveSettings(updatedSettings, emit);
  }

  Future<void> _onToggleNotifications(
    SettingsEventToggleNotifications event,
    Emitter<SettingsState> emit,
  ) async {
    final updatedSettings = state.settings.copyWith(
      notificationsEnabled: !state.settings.notificationsEnabled,
    );
    await _saveSettings(updatedSettings, emit);
  }

  Future<void> _saveSettings(
    AppSettings settings,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await saveSettingsUseCase(settings);

    result.fold(
      (failure) {
        emit(state.copyWith(isLoading: false));
        emitUiEffect(SettingsUiEffect.showError(failure.message));
      },
      (_) {
        emit(state.copyWith(
          settings: settings,
          isLoading: false,
        ));
        emitUiEffect(const SettingsUiEffect.showSuccess('Settings saved successfully'));
      },
    );
  }
}
