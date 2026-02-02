import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:settings/domain/entities/app_settings.dart';
import 'package:settings/domain/repositories/settings_repository.dart';
import 'package:settings/domain/usecases/get_settings_usecase.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late GetSettingsUseCase useCase;
  late MockSettingsRepository mockRepository;

  setUp(() {
    mockRepository = MockSettingsRepository();
    useCase = GetSettingsUseCase(mockRepository);
  });

  group('GetSettingsUseCase', () {
    const tSettings = AppSettings(
      themeMode: ThemeMode.dark,
      language: 'ko',
      notificationsEnabled: false,
    );

    test('should get settings from the repository', () async {
      // Arrange
      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Right(tSettings));

      // Act
      final result = await useCase(NoParams());

      // Assert
      expect(result, const Right(tSettings));
      verify(() => mockRepository.getSettings()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      const tFailure = CacheFailure(message: 'Failed to load settings');
      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Left(tFailure));

      // Act
      final result = await useCase(NoParams());

      // Assert
      expect(result, const Left(tFailure));
      verify(() => mockRepository.getSettings()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return default settings when repository returns them', () async {
      // Arrange
      const tDefaultSettings = AppSettings();
      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Right(tDefaultSettings));

      // Act
      final result = await useCase(NoParams());

      // Assert
      expect(result, const Right(tDefaultSettings));
      verify(() => mockRepository.getSettings()).called(1);
    });
  });
}
