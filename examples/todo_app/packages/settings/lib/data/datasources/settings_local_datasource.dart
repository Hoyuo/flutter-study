import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_settings.dart';

abstract class SettingsLocalDataSource {
  Future<AppSettings> getSettings();
  Future<void> saveSettings(AppSettings settings);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  static const String _keySettings = 'app_settings';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLanguage = 'language';
  static const String _keyNotifications = 'notifications_enabled';

  final SharedPreferences sharedPreferences;

  SettingsLocalDataSourceImpl(this.sharedPreferences);

  @override
  Future<AppSettings> getSettings() async {
    try {
      // Try to get settings as JSON first (new format)
      final jsonString = sharedPreferences.getString(_keySettings);
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return AppSettings.fromJson(json);
      }

      // Fall back to individual keys (legacy format)
      final themeModeString = sharedPreferences.getString(_keyThemeMode);
      final language = sharedPreferences.getString(_keyLanguage);
      final notificationsEnabled = sharedPreferences.getBool(_keyNotifications);

      return AppSettings(
        themeMode: _parseThemeMode(themeModeString),
        language: language ?? 'en',
        notificationsEnabled: notificationsEnabled ?? true,
      );
    } catch (e) {
      // Return default settings on any error
      return const AppSettings();
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    // Save as JSON
    final json = settings.toJson();
    final jsonString = jsonEncode(json);
    await sharedPreferences.setString(_keySettings, jsonString);

    // Also save individual keys for backward compatibility
    await sharedPreferences.setString(
      _keyThemeMode,
      settings.themeMode.name,
    );
    await sharedPreferences.setString(_keyLanguage, settings.language);
    await sharedPreferences.setBool(
      _keyNotifications,
      settings.notificationsEnabled,
    );
  }

  ThemeMode _parseThemeMode(String? value) {
    if (value == null) return ThemeMode.system;

    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
