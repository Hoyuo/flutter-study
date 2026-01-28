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
    const defaultSettings = AppSettings(
      themeMode: ThemeMode.system,
      languageCode: 'en',
      notificationsEnabled: true,
      biometricLockEnabled: false,
    );

    final customSettings = AppSettings(
      themeMode: ThemeMode.dark,
      languageCode: 'ko',
      notificationsEnabled: true,
      biometricLockEnabled: true,
      reminderTime: const TimeOfDay(hour: 21, minute: 0),
    );

    test('성공 시 기본 AppSettings 반환', () async {
      // arrange
      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Right(defaultSettings));

      // act
      final result = await useCase(NoParams());

      // assert
      expect(result, const Right(defaultSettings));
      verify(() => mockRepository.getSettings()).called(1);
    });

    test('성공 시 커스텀 AppSettings 반환', () async {
      // arrange
      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => Right(customSettings));

      // act
      final result = await useCase(NoParams());

      // assert
      expect(result, Right(customSettings));
      expect(
        result.getOrElse((l) => defaultSettings).themeMode,
        ThemeMode.dark,
      );
      expect(
        result.getOrElse((l) => defaultSettings).languageCode,
        'ko',
      );
      expect(
        result.getOrElse((l) => defaultSettings).biometricLockEnabled,
        true,
      );
    });

    test('설정이 없을 때 기본값 반환', () async {
      // arrange
      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Right(defaultSettings));

      // act
      final result = await useCase(NoParams());

      // assert
      expect(result, const Right(defaultSettings));
    });

    test('캐시 에러 시 CacheFailure 반환', () async {
      // arrange
      const failure = Failure.cache(message: '설정을 불러올 수 없습니다');
      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(NoParams());

      // assert
      expect(result, const Left(failure));
    });

    test('알 수 없는 에러 시 UnknownFailure 반환', () async {
      // arrange
      const failure = Failure.unknown(message: '알 수 없는 오류가 발생했습니다');
      when(() => mockRepository.getSettings())
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(NoParams());

      // assert
      expect(result, const Left(failure));
    });
  });
}
