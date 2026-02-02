import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings/data/datasources/settings_local_datasource.dart';
import 'package:settings/domain/entities/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SettingsLocalDataSourceImpl dataSource;
  late SharedPreferences sharedPreferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPreferences = await SharedPreferences.getInstance();
    dataSource = SettingsLocalDataSourceImpl(sharedPreferences);
  });

  group('SettingsLocalDataSource', () {
    group('getSettings', () {
      test('should return default settings when no data is stored', () async {
        // Act
        final result = await dataSource.getSettings();

        // Assert
        expect(result, const AppSettings());
      });

      test('should return settings from JSON format', () async {
        // Arrange
        const tSettings = AppSettings(
          themeMode: ThemeMode.dark,
          language: 'ko',
          notificationsEnabled: false,
        );
        final jsonString = jsonEncode(tSettings.toJson());
        await sharedPreferences.setString('app_settings', jsonString);

        // Act
        final result = await dataSource.getSettings();

        // Assert
        expect(result, tSettings);
      });

      test('should return settings from legacy individual keys format', () async {
        // Arrange
        await sharedPreferences.setString('theme_mode', 'light');
        await sharedPreferences.setString('language', 'es');
        await sharedPreferences.setBool('notifications_enabled', false);

        // Act
        final result = await dataSource.getSettings();

        // Assert
        expect(result.themeMode, ThemeMode.light);
        expect(result.language, 'es');
        expect(result.notificationsEnabled, false);
      });

      test('should prioritize JSON format over legacy format', () async {
        // Arrange
        const tSettings = AppSettings(
          themeMode: ThemeMode.dark,
          language: 'ko',
          notificationsEnabled: false,
        );
        final jsonString = jsonEncode(tSettings.toJson());
        await sharedPreferences.setString('app_settings', jsonString);

        // Also set legacy format with different values
        await sharedPreferences.setString('theme_mode', 'light');
        await sharedPreferences.setString('language', 'en');
        await sharedPreferences.setBool('notifications_enabled', true);

        // Act
        final result = await dataSource.getSettings();

        // Assert
        expect(result, tSettings);
      });

      test('should return default settings on JSON decode error', () async {
        // Arrange
        await sharedPreferences.setString('app_settings', 'invalid json');

        // Act
        final result = await dataSource.getSettings();

        // Assert
        expect(result, const AppSettings());
      });

      test('should handle partial legacy data with defaults', () async {
        // Arrange - only set theme mode
        await sharedPreferences.setString('theme_mode', 'dark');

        // Act
        final result = await dataSource.getSettings();

        // Assert
        expect(result.themeMode, ThemeMode.dark);
        expect(result.language, 'en');
        expect(result.notificationsEnabled, true);
      });

      test('should parse all ThemeMode values from legacy format', () async {
        // Test light
        await sharedPreferences.setString('theme_mode', 'light');
        var result = await dataSource.getSettings();
        expect(result.themeMode, ThemeMode.light);

        // Test dark
        await sharedPreferences.setString('theme_mode', 'dark');
        result = await dataSource.getSettings();
        expect(result.themeMode, ThemeMode.dark);

        // Test system
        await sharedPreferences.setString('theme_mode', 'system');
        result = await dataSource.getSettings();
        expect(result.themeMode, ThemeMode.system);
      });

      test('should return system theme for invalid theme mode string', () async {
        // Arrange
        await sharedPreferences.setString('theme_mode', 'invalid');

        // Act
        final result = await dataSource.getSettings();

        // Assert
        expect(result.themeMode, ThemeMode.system);
      });

      test('should return system theme for null theme mode', () async {
        // Arrange - no theme mode set
        await sharedPreferences.setString('language', 'en');

        // Act
        final result = await dataSource.getSettings();

        // Assert
        expect(result.themeMode, ThemeMode.system);
      });
    });

    group('saveSettings', () {
      const tSettings = AppSettings(
        themeMode: ThemeMode.dark,
        language: 'ko',
        notificationsEnabled: false,
      );

      test('should save settings in JSON format', () async {
        // Act
        await dataSource.saveSettings(tSettings);

        // Assert
        final jsonString = sharedPreferences.getString('app_settings');
        expect(jsonString, isNotNull);
        final json = jsonDecode(jsonString!);
        expect(json['themeMode'], 'dark');
        expect(json['language'], 'ko');
        expect(json['notificationsEnabled'], false);
      });

      test('should also save individual keys for backward compatibility', () async {
        // Act
        await dataSource.saveSettings(tSettings);

        // Assert
        expect(sharedPreferences.getString('theme_mode'), 'dark');
        expect(sharedPreferences.getString('language'), 'ko');
        expect(sharedPreferences.getBool('notifications_enabled'), false);
      });

      test('should save default settings correctly', () async {
        // Arrange
        const defaultSettings = AppSettings();

        // Act
        await dataSource.saveSettings(defaultSettings);

        // Assert
        final jsonString = sharedPreferences.getString('app_settings');
        final json = jsonDecode(jsonString!);
        expect(json['themeMode'], 'system');
        expect(json['language'], 'en');
        expect(json['notificationsEnabled'], true);
      });

      test('should save all ThemeMode values correctly', () async {
        // Test light
        await dataSource.saveSettings(
          const AppSettings(themeMode: ThemeMode.light),
        );
        expect(sharedPreferences.getString('theme_mode'), 'light');

        // Test dark
        await dataSource.saveSettings(
          const AppSettings(themeMode: ThemeMode.dark),
        );
        expect(sharedPreferences.getString('theme_mode'), 'dark');

        // Test system
        await dataSource.saveSettings(
          const AppSettings(themeMode: ThemeMode.system),
        );
        expect(sharedPreferences.getString('theme_mode'), 'system');
      });

      test('should overwrite existing settings', () async {
        // Arrange - save initial settings
        const initialSettings = AppSettings(
          themeMode: ThemeMode.light,
          language: 'en',
          notificationsEnabled: true,
        );
        await dataSource.saveSettings(initialSettings);

        // Act - save new settings
        await dataSource.saveSettings(tSettings);

        // Assert
        final result = await dataSource.getSettings();
        expect(result, tSettings);
      });

      test('should roundtrip save and load correctly', () async {
        // Act
        await dataSource.saveSettings(tSettings);
        final result = await dataSource.getSettings();

        // Assert
        expect(result, tSettings);
      });
    });
  });
}
