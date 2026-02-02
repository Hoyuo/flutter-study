part of 'settings_bloc.dart';

@freezed
abstract class SettingsState with _$SettingsState {
  const SettingsState._();

  const factory SettingsState({
    @Default(AppSettings()) AppSettings settings,
    @Default(false) bool isLoading,
  }) = _SettingsState;
}

@freezed
sealed class SettingsUiEffect with _$SettingsUiEffect {
  const factory SettingsUiEffect.showSuccess(String message) = _ShowSuccess;
  const factory SettingsUiEffect.showError(String message) = _ShowError;
}
