import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:settings/domain/entities/app_settings.dart';
import 'package:settings/domain/repositories/settings_repository.dart';
import 'package:settings/domain/usecases/update_settings_usecase.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late UpdateSettingsUseCase useCase;
  late MockSettingsRepository mockRepository;

  setUpAll(() {
    // mocktail registerFallbackValue
    registerFallbackValue(
      const AppSettings(),
    );
  });

  setUp(() {
    mockRepository = MockSettingsRepository();
    useCase = UpdateSettingsUseCase(mockRepository);
  });

  group('UpdateSettingsUseCase', () {
    const defaultSettings = AppSettings(
      themeMode: ThemeMode.system,
      languageCode: 'en',
      notificationsEnabled: true,
      biometricLockEnabled: false,
    );

    test('테마 모드 변경 성공', () async {
      // arrange
      const updatedSettings = AppSettings(
        themeMode: ThemeMode.dark,
        languageCode: 'en',
        notificationsEnabled: true,
        biometricLockEnabled: false,
      );
      const params = UpdateSettingsParams(settings: updatedSettings);
      when(() => mockRepository.updateSettings(any()))
          .thenAnswer((_) async => const Right(updatedSettings));

      // act
      final result = await useCase(params);

      // assert
      expect(result, const Right(updatedSettings));
      verify(() => mockRepository.updateSettings(updatedSettings)).called(1);
    });

    test('언어 변경 성공', () async {
      // arrange
      const updatedSettings = AppSettings(
        themeMode: ThemeMode.system,
        languageCode: 'ko',
        notificationsEnabled: true,
        biometricLockEnabled: false,
      );
      const params = UpdateSettingsParams(settings: updatedSettings);
      when(() => mockRepository.updateSettings(any()))
          .thenAnswer((_) async => const Right(updatedSettings));

      // act
      final result = await useCase(params);

      // assert
      expect(result, const Right(updatedSettings));
      expect(
        result.getOrElse((l) => defaultSettings).languageCode,
        'ko',
      );
    });

    test('알림 설정 변경 성공', () async {
      // arrange
      const updatedSettings = AppSettings(
        themeMode: ThemeMode.system,
        languageCode: 'en',
        notificationsEnabled: false,
        biometricLockEnabled: false,
      );
      const params = UpdateSettingsParams(settings: updatedSettings);
      when(() => mockRepository.updateSettings(any()))
          .thenAnswer((_) async => const Right(updatedSettings));

      // act
      final result = await useCase(params);

      // assert
      expect(result, const Right(updatedSettings));
      expect(
        result.getOrElse((l) => defaultSettings).notificationsEnabled,
        false,
      );
    });

    test('생체 인증 잠금 활성화 성공', () async {
      // arrange
      const updatedSettings = AppSettings(
        themeMode: ThemeMode.system,
        languageCode: 'en',
        notificationsEnabled: true,
        biometricLockEnabled: true,
      );
      const params = UpdateSettingsParams(settings: updatedSettings);
      when(() => mockRepository.updateSettings(any()))
          .thenAnswer((_) async => const Right(updatedSettings));

      // act
      final result = await useCase(params);

      // assert
      expect(result, const Right(updatedSettings));
      expect(
        result.getOrElse((l) => defaultSettings).biometricLockEnabled,
        true,
      );
    });

    test('리마인더 시간 설정 성공', () async {
      // arrange
      final updatedSettings = AppSettings(
        themeMode: ThemeMode.system,
        languageCode: 'en',
        notificationsEnabled: true,
        biometricLockEnabled: false,
        reminderTime: const TimeOfDay(hour: 20, minute: 30),
      );
      final params = UpdateSettingsParams(settings: updatedSettings);
      when(() => mockRepository.updateSettings(any()))
          .thenAnswer((_) async => Right(updatedSettings));

      // act
      final result = await useCase(params);

      // assert
      expect(result, Right(updatedSettings));
      expect(
        result.getOrElse((l) => defaultSettings).reminderTime,
        const TimeOfDay(hour: 20, minute: 30),
      );
    });

    test('여러 설정 동시 변경 성공', () async {
      // arrange
      final updatedSettings = AppSettings(
        themeMode: ThemeMode.dark,
        languageCode: 'ko',
        notificationsEnabled: false,
        biometricLockEnabled: true,
        reminderTime: const TimeOfDay(hour: 21, minute: 0),
      );
      final params = UpdateSettingsParams(settings: updatedSettings);
      when(() => mockRepository.updateSettings(any()))
          .thenAnswer((_) async => Right(updatedSettings));

      // act
      final result = await useCase(params);

      // assert
      expect(result, Right(updatedSettings));
      final settings = result.getOrElse((l) => defaultSettings);
      expect(settings.themeMode, ThemeMode.dark);
      expect(settings.languageCode, 'ko');
      expect(settings.notificationsEnabled, false);
      expect(settings.biometricLockEnabled, true);
      expect(settings.reminderTime, const TimeOfDay(hour: 21, minute: 0));
    });

    test('캐시 에러 시 CacheFailure 반환', () async {
      // arrange
      const failure = Failure.cache(message: '설정을 저장할 수 없습니다');
      const params = UpdateSettingsParams(settings: defaultSettings);
      when(() => mockRepository.updateSettings(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(params);

      // assert
      expect(result, const Left(failure));
    });

    test('알 수 없는 에러 시 UnknownFailure 반환', () async {
      // arrange
      const failure = Failure.unknown(message: '설정 업데이트 실패');
      const params = UpdateSettingsParams(settings: defaultSettings);
      when(() => mockRepository.updateSettings(any()))
          .thenAnswer((_) async => const Left(failure));

      // act
      final result = await useCase(params);

      // assert
      expect(result, const Left(failure));
    });
  });
}
