import '../models/models.dart';

/// Abstract data source for local settings storage
abstract class SettingsLocalDataSource {
  /// Gets the stored app settings
  ///
  /// Returns null if no settings are stored
  /// Throws an exception if reading fails
  Future<AppSettingsModel?> getSettings();

  /// Saves the app settings to local storage
  ///
  /// Throws an exception if saving fails
  Future<void> saveSettings(AppSettingsModel settings);
}
