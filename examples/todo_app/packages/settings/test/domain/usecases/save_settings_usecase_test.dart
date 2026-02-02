import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:settings/domain/entities/app_settings.dart';
import 'package:settings/domain/repositories/settings_repository.dart';
import 'package:settings/domain/usecases/save_settings_usecase.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late SaveSettingsUseCase useCase;
  late MockSettingsRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(const AppSettings());
  });

  setUp(() {
    mockRepository = MockSettingsRepository();
    useCase = SaveSettingsUseCase(mockRepository);
  });

  group('SaveSettingsUseCase', () {
    const tSettings = AppSettings(
      themeMode: ThemeMode.dark,
      language: 'ko',
      notificationsEnabled: false,
    );

    test('should save settings to the repository', () async {
      // Arrange
      when(() => mockRepository.saveSettings(any()))
          .thenAnswer((_) async => const Right(unit));

      // Act
      final result = await useCase(tSettings);

      // Assert
      expect(result, const Right(unit));
      verify(() => mockRepository.saveSettings(tSettings)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const tFailure = CacheFailure(message: 'Failed to save settings');
      when(() => mockRepository.saveSettings(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(tSettings);

      // Assert
      expect(result, const Left(tFailure));
      verify(() => mockRepository.saveSettings(tSettings)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should save default settings', () async {
      // Arrange
      const tDefaultSettings = AppSettings();
      when(() => mockRepository.saveSettings(any()))
          .thenAnswer((_) async => const Right(unit));

      // Act
      final result = await useCase(tDefaultSettings);

      // Assert
      expect(result, const Right(unit));
      verify(() => mockRepository.saveSettings(tDefaultSettings)).called(1);
    });

    test('should save settings with different theme modes', () async {
      // Arrange
      when(() => mockRepository.saveSettings(any()))
          .thenAnswer((_) async => const Right(unit));

      // Test light mode
      var settings = const AppSettings(themeMode: ThemeMode.light);
      await useCase(settings);
      verify(() => mockRepository.saveSettings(settings)).called(1);

      // Test dark mode
      settings = const AppSettings(themeMode: ThemeMode.dark);
      await useCase(settings);
      verify(() => mockRepository.saveSettings(settings)).called(1);

      // Test system mode
      settings = const AppSettings(themeMode: ThemeMode.system);
      await useCase(settings);
      verify(() => mockRepository.saveSettings(settings)).called(1);
    });
  });
}
