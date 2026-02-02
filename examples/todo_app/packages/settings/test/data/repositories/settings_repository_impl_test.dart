import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:settings/data/datasources/settings_local_datasource.dart';
import 'package:settings/data/repositories/settings_repository_impl.dart';
import 'package:settings/domain/entities/app_settings.dart';

class MockSettingsLocalDataSource extends Mock implements SettingsLocalDataSource {}

void main() {
  late SettingsRepositoryImpl repository;
  late MockSettingsLocalDataSource mockLocalDataSource;

  setUpAll(() {
    registerFallbackValue(const AppSettings());
  });

  setUp(() {
    mockLocalDataSource = MockSettingsLocalDataSource();
    repository = SettingsRepositoryImpl(mockLocalDataSource);
  });

  group('SettingsRepositoryImpl', () {
    group('getSettings', () {
      const tSettings = AppSettings(
        themeMode: ThemeMode.dark,
        language: 'ko',
        notificationsEnabled: false,
      );

      test('should return settings when local data source succeeds', () async {
        // Arrange
        when(() => mockLocalDataSource.getSettings())
            .thenAnswer((_) async => tSettings);

        // Act
        final result = await repository.getSettings();

        // Assert
        expect(result, const Right(tSettings));
        verify(() => mockLocalDataSource.getSettings()).called(1);
        verifyNoMoreInteractions(mockLocalDataSource);
      });

      test('should return default settings when local data source returns them', () async {
        // Arrange
        const defaultSettings = AppSettings();
        when(() => mockLocalDataSource.getSettings())
            .thenAnswer((_) async => defaultSettings);

        // Act
        final result = await repository.getSettings();

        // Assert
        expect(result, const Right(defaultSettings));
        verify(() => mockLocalDataSource.getSettings()).called(1);
      });

      test('should return CacheFailure when local data source throws exception', () async {
        // Arrange
        when(() => mockLocalDataSource.getSettings())
            .thenThrow(Exception('Database error'));

        // Act
        final result = await repository.getSettings();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<CacheFailure>());
            expect(failure.message, contains('Failed to load settings'));
            expect(failure.message, contains('Database error'));
          },
          (_) => fail('Should return Left'),
        );
        verify(() => mockLocalDataSource.getSettings()).called(1);
      });

      test('should return CacheFailure on any error type', () async {
        // Arrange
        when(() => mockLocalDataSource.getSettings())
            .thenThrow('String error');

        // Act
        final result = await repository.getSettings();

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<CacheFailure>());
            expect(failure.message, contains('Failed to load settings'));
          },
          (_) => fail('Should return Left'),
        );
      });
    });

    group('saveSettings', () {
      const tSettings = AppSettings(
        themeMode: ThemeMode.dark,
        language: 'ko',
        notificationsEnabled: false,
      );

      test('should return unit when local data source saves successfully', () async {
        // Arrange
        when(() => mockLocalDataSource.saveSettings(any()))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.saveSettings(tSettings);

        // Assert
        expect(result, const Right(unit));
        verify(() => mockLocalDataSource.saveSettings(tSettings)).called(1);
        verifyNoMoreInteractions(mockLocalDataSource);
      });

      test('should save default settings successfully', () async {
        // Arrange
        const defaultSettings = AppSettings();
        when(() => mockLocalDataSource.saveSettings(any()))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.saveSettings(defaultSettings);

        // Assert
        expect(result, const Right(unit));
        verify(() => mockLocalDataSource.saveSettings(defaultSettings)).called(1);
      });

      test('should return CacheFailure when local data source throws exception', () async {
        // Arrange
        when(() => mockLocalDataSource.saveSettings(any()))
            .thenThrow(Exception('Write error'));

        // Act
        final result = await repository.saveSettings(tSettings);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<CacheFailure>());
            expect(failure.message, contains('Failed to save settings'));
            expect(failure.message, contains('Write error'));
          },
          (_) => fail('Should return Left'),
        );
        verify(() => mockLocalDataSource.saveSettings(tSettings)).called(1);
      });

      test('should return CacheFailure on any error type', () async {
        // Arrange
        when(() => mockLocalDataSource.saveSettings(any()))
            .thenThrow('String error');

        // Act
        final result = await repository.saveSettings(tSettings);

        // Assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<CacheFailure>());
            expect(failure.message, contains('Failed to save settings'));
          },
          (_) => fail('Should return Left'),
        );
      });

      test('should save settings with all theme modes', () async {
        // Arrange
        when(() => mockLocalDataSource.saveSettings(any()))
            .thenAnswer((_) async => Future.value());

        // Test light mode
        var settings = const AppSettings(themeMode: ThemeMode.light);
        var result = await repository.saveSettings(settings);
        expect(result, const Right(unit));
        verify(() => mockLocalDataSource.saveSettings(settings)).called(1);

        // Test dark mode
        settings = const AppSettings(themeMode: ThemeMode.dark);
        result = await repository.saveSettings(settings);
        expect(result, const Right(unit));
        verify(() => mockLocalDataSource.saveSettings(settings)).called(1);

        // Test system mode
        settings = const AppSettings(themeMode: ThemeMode.system);
        result = await repository.saveSettings(settings);
        expect(result, const Right(unit));
        verify(() => mockLocalDataSource.saveSettings(settings)).called(1);
      });
    });
  });
}
