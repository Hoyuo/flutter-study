import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settings/domain/entities/app_settings.dart';

void main() {
  group('AppSettings', () {
    test('should create AppSettings with default values', () {
      // Arrange & Act
      const settings = AppSettings();

      // Assert
      expect(settings.themeMode, ThemeMode.system);
      expect(settings.language, 'en');
      expect(settings.notificationsEnabled, true);
    });

    test('should create AppSettings with custom values', () {
      // Arrange & Act
      const settings = AppSettings(
        themeMode: ThemeMode.dark,
        language: 'ko',
        notificationsEnabled: false,
      );

      // Assert
      expect(settings.themeMode, ThemeMode.dark);
      expect(settings.language, 'ko');
      expect(settings.notificationsEnabled, false);
    });

    test('should support value equality', () {
      // Arrange
      const settings1 = AppSettings(
        themeMode: ThemeMode.light,
        language: 'en',
        notificationsEnabled: true,
      );
      const settings2 = AppSettings(
        themeMode: ThemeMode.light,
        language: 'en',
        notificationsEnabled: true,
      );
      const settings3 = AppSettings(
        themeMode: ThemeMode.dark,
        language: 'en',
        notificationsEnabled: true,
      );

      // Assert
      expect(settings1, settings2);
      expect(settings1, isNot(settings3));
    });

    test('should create a copy with modified values', () {
      // Arrange
      const original = AppSettings(
        themeMode: ThemeMode.light,
        language: 'en',
        notificationsEnabled: true,
      );

      // Act
      final modified = original.copyWith(themeMode: ThemeMode.dark);

      // Assert
      expect(modified.themeMode, ThemeMode.dark);
      expect(modified.language, 'en');
      expect(modified.notificationsEnabled, true);
    });

    group('JSON serialization', () {
      test('should serialize to JSON correctly', () {
        // Arrange
        const settings = AppSettings(
          themeMode: ThemeMode.dark,
          language: 'ko',
          notificationsEnabled: false,
        );

        // Act
        final json = settings.toJson();

        // Assert
        expect(json, {
          'themeMode': 'dark',
          'language': 'ko',
          'notificationsEnabled': false,
        });
      });

      test('should deserialize from JSON correctly', () {
        // Arrange
        final json = {
          'themeMode': 'light',
          'language': 'es',
          'notificationsEnabled': true,
        };

        // Act
        final settings = AppSettings.fromJson(json);

        // Assert
        expect(settings.themeMode, ThemeMode.light);
        expect(settings.language, 'es');
        expect(settings.notificationsEnabled, true);
      });

      test('should deserialize from JSON with default values', () {
        // Arrange
        final json = <String, dynamic>{};

        // Act
        final settings = AppSettings.fromJson(json);

        // Assert
        expect(settings.themeMode, ThemeMode.system);
        expect(settings.language, 'en');
        expect(settings.notificationsEnabled, true);
      });

      test('should handle all ThemeMode values in JSON', () {
        // Test system
        var json = {'themeMode': 'system'};
        var settings = AppSettings.fromJson(json);
        expect(settings.themeMode, ThemeMode.system);

        // Test light
        json = {'themeMode': 'light'};
        settings = AppSettings.fromJson(json);
        expect(settings.themeMode, ThemeMode.light);

        // Test dark
        json = {'themeMode': 'dark'};
        settings = AppSettings.fromJson(json);
        expect(settings.themeMode, ThemeMode.dark);
      });

      test('should roundtrip JSON serialization', () {
        // Arrange
        const original = AppSettings(
          themeMode: ThemeMode.light,
          language: 'fr',
          notificationsEnabled: false,
        );

        // Act
        final json = original.toJson();
        final deserialized = AppSettings.fromJson(json);

        // Assert
        expect(deserialized, original);
      });
    });
  });
}
