import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'settings_local_datasource.dart';

/// Implementation of [SettingsLocalDataSource] using SharedPreferences
class SharedPreferencesSettingsDataSourceImpl
    implements SettingsLocalDataSource {
  final SharedPreferences _preferences;

  /// Key for storing settings in SharedPreferences
  static const String _settingsKey = 'app_settings';

  SharedPreferencesSettingsDataSourceImpl(this._preferences);

  @override
  Future<AppSettingsModel?> getSettings() async {
    try {
      final jsonString = _preferences.getString(_settingsKey);
      if (jsonString == null) return null;

      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return AppSettingsModel.fromJson(jsonMap);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> saveSettings(AppSettingsModel settings) async {
    try {
      final jsonString = jsonEncode(settings.toJson());
      await _preferences.setString(_settingsKey, jsonString);
    } catch (e) {
      rethrow;
    }
  }
}
