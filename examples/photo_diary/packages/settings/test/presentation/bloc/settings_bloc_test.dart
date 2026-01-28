import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:settings/domain/entities/entities.dart';
import 'package:settings/domain/usecases/usecases.dart';
import 'package:settings/presentation/bloc/settings_bloc.dart';
import 'package:settings/presentation/bloc/settings_event.dart';
import 'package:settings/presentation/bloc/settings_state.dart';

// Mock 클래스
class MockGetSettingsUseCase extends Mock implements GetSettingsUseCase {}

class MockUpdateSettingsUseCase extends Mock implements UpdateSettingsUseCase {}

// Fake 클래스
class FakeNoParams extends Fake implements NoParams {}

class FakeUpdateSettingsParams extends Fake implements UpdateSettingsParams {}

void main() {
  late SettingsBloc bloc;
  late MockGetSettingsUseCase mockGetSettings;
  late MockUpdateSettingsUseCase mockUpdateSettings;

  // 테스트용 설정 데이터
  const defaultSettings = AppSettings();

  const customSettings = AppSettings(
    themeMode: ThemeMode.dark,
    languageCode: 'ko',
    notificationsEnabled: false,
    biometricLockEnabled: true,
  );

  setUpAll(() {
    // Fake 클래스 등록
    registerFallbackValue(FakeNoParams());
    registerFallbackValue(FakeUpdateSettingsParams());
  });

  setUp(() {
    mockGetSettings = MockGetSettingsUseCase();
    mockUpdateSettings = MockUpdateSettingsUseCase();

    bloc = SettingsBloc(
      getSettingsUseCase: mockGetSettings,
      updateSettingsUseCase: mockUpdateSettings,
    );
  });

  tearDown(() => bloc.close());

  group('SettingsBloc', () {
    test('초기 상태 확인', () {
      expect(bloc.state.settings, isNull);
      expect(bloc.state.isLoading, isTrue); // initial()에서 true로 설정됨
      expect(bloc.state.isSaving, isFalse);
      expect(bloc.state.failure, isNull);
    });

    group('설정 로드 (LoadSettings)', () {
      blocTest<SettingsBloc, SettingsState>(
        '설정 로드 성공',
        build: () {
          when(() => mockGetSettings(any())).thenAnswer(
            (_) async => const Right(defaultSettings),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const SettingsEvent.loadSettings()),
        expect: () => [
          // 로딩 시작
          isA<SettingsState>()
              .having((s) => s.isLoading, 'isLoading', true)
              .having((s) => s.failure, 'failure', isNull),
          // 로드 완료
          isA<SettingsState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.settings, 'settings', defaultSettings)
              .having((s) => s.failure, 'failure', isNull),
        ],
        verify: (_) {
          verify(() => mockGetSettings(any())).called(1);
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        '설정 로드 실패',
        build: () {
          when(() => mockGetSettings(any())).thenAnswer(
            (_) async => const Left(Failure.cache(message: '로컬 저장소 읽기 실패')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const SettingsEvent.loadSettings()),
        expect: () => [
          // 로딩 시작
          isA<SettingsState>().having((s) => s.isLoading, 'isLoading', true),
          // 로드 실패
          isA<SettingsState>()
              .having((s) => s.isLoading, 'isLoading', false)
              .having((s) => s.settings, 'settings', isNull)
              .having((s) => s.failure, 'failure', isNotNull)
              .having(
                  (s) => s.failure?.message, 'failure message', '로컬 저장소 읽기 실패'),
        ],
      );
    });

    group('테마 모드 업데이트 (UpdateThemeMode)', () {
      blocTest<SettingsBloc, SettingsState>(
        '테마 모드 업데이트 성공',
        build: () {
          when(() => mockUpdateSettings(any())).thenAnswer(
            (_) async => const Right(
              AppSettings(themeMode: ThemeMode.dark),
            ),
          );
          return bloc;
        },
        seed: () => const SettingsState(settings: defaultSettings),
        act: (bloc) =>
            bloc.add(const SettingsEvent.updateThemeMode(ThemeMode.dark)),
        expect: () => [
          // 저장 시작
          isA<SettingsState>()
              .having((s) => s.isSaving, 'isSaving', true)
              .having((s) => s.failure, 'failure', isNull),
          // 저장 완료
          isA<SettingsState>()
              .having((s) => s.isSaving, 'isSaving', false)
              .having((s) => s.settings?.themeMode, 'themeMode', ThemeMode.dark)
              .having((s) => s.failure, 'failure', isNull),
        ],
        verify: (_) {
          verify(() => mockUpdateSettings(any())).called(1);
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        '현재 설정이 없을 때 업데이트 무시',
        build: () => bloc,
        seed: () => const SettingsState(settings: null),
        act: (bloc) =>
            bloc.add(const SettingsEvent.updateThemeMode(ThemeMode.dark)),
        expect: () => [],
        verify: (_) {
          verifyNever(() => mockUpdateSettings(any()));
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        '테마 모드 업데이트 실패',
        build: () {
          when(() => mockUpdateSettings(any())).thenAnswer(
            (_) async => const Left(Failure.cache(message: '저장 실패')),
          );
          return bloc;
        },
        seed: () => const SettingsState(settings: defaultSettings),
        act: (bloc) =>
            bloc.add(const SettingsEvent.updateThemeMode(ThemeMode.dark)),
        expect: () => [
          // 저장 시작
          isA<SettingsState>().having((s) => s.isSaving, 'isSaving', true),
          // 저장 실패
          isA<SettingsState>()
              .having((s) => s.isSaving, 'isSaving', false)
              .having((s) => s.failure, 'failure', isNotNull)
              .having((s) => s.failure?.message, 'failure message', '저장 실패'),
        ],
      );
    });

    group('언어 업데이트 (UpdateLocale)', () {
      blocTest<SettingsBloc, SettingsState>(
        '언어 업데이트 성공',
        build: () {
          when(() => mockUpdateSettings(any())).thenAnswer(
            (_) async => const Right(AppSettings(languageCode: 'ko')),
          );
          return bloc;
        },
        seed: () => const SettingsState(settings: defaultSettings),
        act: (bloc) => bloc.add(const SettingsEvent.updateLocale(Locale('ko'))),
        expect: () => [
          // 저장 시작
          isA<SettingsState>().having((s) => s.isSaving, 'isSaving', true),
          // 저장 완료
          isA<SettingsState>()
              .having((s) => s.isSaving, 'isSaving', false)
              .having((s) => s.settings?.languageCode, 'languageCode', 'ko')
              .having((s) => s.failure, 'failure', isNull),
        ],
        verify: (_) {
          verify(() => mockUpdateSettings(any())).called(1);
        },
      );
    });

    group('생체인증 토글 (ToggleBiometricAuth)', () {
      blocTest<SettingsBloc, SettingsState>(
        '생체인증 활성화',
        build: () {
          when(() => mockUpdateSettings(any())).thenAnswer(
            (_) async => const Right(AppSettings(biometricLockEnabled: true)),
          );
          return bloc;
        },
        seed: () => const SettingsState(settings: defaultSettings),
        act: (bloc) => bloc.add(const SettingsEvent.toggleBiometricAuth(true)),
        expect: () => [
          // 저장 시작
          isA<SettingsState>().having((s) => s.isSaving, 'isSaving', true),
          // 저장 완료
          isA<SettingsState>()
              .having((s) => s.isSaving, 'isSaving', false)
              .having((s) => s.settings?.biometricLockEnabled,
                  'biometricLockEnabled', true)
              .having((s) => s.failure, 'failure', isNull),
        ],
      );

      blocTest<SettingsBloc, SettingsState>(
        '생체인증 비활성화',
        build: () {
          when(() => mockUpdateSettings(any())).thenAnswer(
            (_) async => const Right(AppSettings(biometricLockEnabled: false)),
          );
          return bloc;
        },
        seed: () => const SettingsState(
            settings: AppSettings(biometricLockEnabled: true)),
        act: (bloc) => bloc.add(const SettingsEvent.toggleBiometricAuth(false)),
        expect: () => [
          // 저장 시작
          isA<SettingsState>().having((s) => s.isSaving, 'isSaving', true),
          // 저장 완료
          isA<SettingsState>()
              .having((s) => s.isSaving, 'isSaving', false)
              .having((s) => s.settings?.biometricLockEnabled,
                  'biometricLockEnabled', false),
        ],
      );
    });

    group('푸시 알림 토글 (TogglePushNotification)', () {
      blocTest<SettingsBloc, SettingsState>(
        '푸시 알림 비활성화',
        build: () {
          when(() => mockUpdateSettings(any())).thenAnswer(
            (_) async => const Right(AppSettings(notificationsEnabled: false)),
          );
          return bloc;
        },
        seed: () => const SettingsState(settings: defaultSettings),
        act: (bloc) =>
            bloc.add(const SettingsEvent.togglePushNotification(false)),
        expect: () => [
          // 저장 시작
          isA<SettingsState>().having((s) => s.isSaving, 'isSaving', true),
          // 저장 완료
          isA<SettingsState>()
              .having((s) => s.isSaving, 'isSaving', false)
              .having((s) => s.settings?.notificationsEnabled,
                  'notificationsEnabled', false)
              .having((s) => s.failure, 'failure', isNull),
        ],
      );

      blocTest<SettingsBloc, SettingsState>(
        '푸시 알림 활성화',
        build: () {
          when(() => mockUpdateSettings(any())).thenAnswer(
            (_) async => const Right(AppSettings(notificationsEnabled: true)),
          );
          return bloc;
        },
        seed: () => const SettingsState(
            settings: AppSettings(notificationsEnabled: false)),
        act: (bloc) =>
            bloc.add(const SettingsEvent.togglePushNotification(true)),
        expect: () => [
          // 저장 시작
          isA<SettingsState>().having((s) => s.isSaving, 'isSaving', true),
          // 저장 완료
          isA<SettingsState>()
              .having((s) => s.isSaving, 'isSaving', false)
              .having((s) => s.settings?.notificationsEnabled,
                  'notificationsEnabled', true),
        ],
      );
    });

    group('설정 초기화 (ResetSettings)', () {
      blocTest<SettingsBloc, SettingsState>(
        '설정 초기화 성공',
        build: () {
          when(() => mockUpdateSettings(any())).thenAnswer(
            (_) async => const Right(defaultSettings),
          );
          return bloc;
        },
        seed: () => const SettingsState(settings: customSettings),
        act: (bloc) => bloc.add(const SettingsEvent.resetSettings()),
        expect: () => [
          // 저장 시작
          isA<SettingsState>().having((s) => s.isSaving, 'isSaving', true),
          // 초기화 완료
          isA<SettingsState>()
              .having((s) => s.isSaving, 'isSaving', false)
              .having((s) => s.settings, 'settings', defaultSettings)
              .having((s) => s.failure, 'failure', isNull),
        ],
        verify: (_) {
          verify(() => mockUpdateSettings(any())).called(1);
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        '설정 초기화 실패',
        build: () {
          when(() => mockUpdateSettings(any())).thenAnswer(
            (_) async => const Left(Failure.cache(message: '초기화 실패')),
          );
          return bloc;
        },
        seed: () => const SettingsState(settings: customSettings),
        act: (bloc) => bloc.add(const SettingsEvent.resetSettings()),
        expect: () => [
          // 저장 시작
          isA<SettingsState>().having((s) => s.isSaving, 'isSaving', true),
          // 초기화 실패
          isA<SettingsState>()
              .having((s) => s.isSaving, 'isSaving', false)
              .having((s) => s.settings, 'settings', customSettings)
              .having((s) => s.failure, 'failure', isNotNull)
              .having((s) => s.failure?.message, 'failure message', '초기화 실패'),
        ],
      );
    });

    group('다양한 시나리오', () {
      blocTest<SettingsBloc, SettingsState>(
        '연속된 설정 변경',
        build: () {
          when(() => mockUpdateSettings(any())).thenAnswer(
            (_) async => const Right(
              AppSettings(
                themeMode: ThemeMode.dark,
                languageCode: 'ko',
              ),
            ),
          );
          return bloc;
        },
        seed: () => const SettingsState(settings: defaultSettings),
        act: (bloc) async {
          bloc.add(const SettingsEvent.updateThemeMode(ThemeMode.dark));
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(const SettingsEvent.updateLocale(Locale('ko')));
        },
        skip: 2, // 첫 번째 변경 결과는 건너뜀
        expect: () => [
          // 두 번째 변경 - 저장 시작
          isA<SettingsState>().having((s) => s.isSaving, 'isSaving', true),
          // 두 번째 변경 완료
          isA<SettingsState>()
              .having((s) => s.isSaving, 'isSaving', false)
              .having((s) => s.settings?.themeMode, 'themeMode', ThemeMode.dark)
              .having((s) => s.settings?.languageCode, 'languageCode', 'ko'),
        ],
      );
    });
  });
}
