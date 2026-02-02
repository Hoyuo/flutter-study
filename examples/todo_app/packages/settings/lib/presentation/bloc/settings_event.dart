part of 'settings_bloc.dart';

@freezed
sealed class SettingsEvent with _$SettingsEvent {
  const factory SettingsEvent.loadSettings() = SettingsEventLoadSettings;

  const factory SettingsEvent.updateTheme(ThemeMode themeMode) = SettingsEventUpdateTheme;

  const factory SettingsEvent.updateLanguage(String language) = SettingsEventUpdateLanguage;

  const factory SettingsEvent.toggleNotifications() = SettingsEventToggleNotifications;
}
