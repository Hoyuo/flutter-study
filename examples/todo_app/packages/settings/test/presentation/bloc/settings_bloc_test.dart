import 'package:bloc_test/bloc_test.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:settings/domain/entities/app_settings.dart';
import 'package:settings/domain/usecases/get_settings_usecase.dart';
import 'package:settings/domain/usecases/save_settings_usecase.dart';
import 'package:settings/presentation/bloc/settings_bloc.dart';

class MockGetSettingsUseCase extends Mock implements GetSettingsUseCase {}

class MockSaveSettingsUseCase extends Mock implements SaveSettingsUseCase {}

void main() {
  late SettingsBloc bloc;
  late MockGetSettingsUseCase mockGetSettingsUseCase;
  late MockSaveSettingsUseCase mockSaveSettingsUseCase;

  setUpAll(() {
    registerFallbackValue(NoParams());
    registerFallbackValue(const AppSettings());
  });

  setUp(() {
    mockGetSettingsUseCase = MockGetSettingsUseCase();
    mockSaveSettingsUseCase = MockSaveSettingsUseCase();
    bloc = SettingsBloc(
      getSettingsUseCase: mockGetSettingsUseCase,
      saveSettingsUseCase: mockSaveSettingsUseCase,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('SettingsBloc', () {
    test('initial state should have default settings and not loading', () {
      expect(bloc.state.settings, const AppSettings());
      expect(bloc.state.isLoading, false);
    });

    group('SettingsEventLoadSettings', () {
      const tSettings = AppSettings(
        themeMode: ThemeMode.dark,
        language: 'ko',
        notificationsEnabled: false,
      );

      blocTest<SettingsBloc, SettingsState>(
        'should emit loading state then loaded state when settings are retrieved successfully',
        build: () {
          when(() => mockGetSettingsUseCase(any()))
              .thenAnswer((_) async => const Right(tSettings));
          return bloc;
        },
        act: (bloc) => bloc.add(const SettingsEvent.loadSettings()),
        expect: () => [
          const SettingsState(isLoading: true),
          const SettingsState(settings: tSettings, isLoading: false),
        ],
        verify: (_) {
          verify(() => mockGetSettingsUseCase(any())).called(1);
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'should emit loading state then error when loading fails',
        build: () {
          when(() => mockGetSettingsUseCase(any())).thenAnswer(
            (_) async => const Left(CacheFailure(message: 'Load error')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const SettingsEvent.loadSettings()),
        expect: () => [
          const SettingsState(isLoading: true),
          const SettingsState(isLoading: false),
        ],
        verify: (_) {
          verify(() => mockGetSettingsUseCase(any())).called(1);
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'should emit error UI effect when loading fails',
        build: () {
          when(() => mockGetSettingsUseCase(any())).thenAnswer(
            (_) async => const Left(CacheFailure(message: 'Load error')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const SettingsEvent.loadSettings()),
        expect: () => [
          const SettingsState(isLoading: true),
          const SettingsState(isLoading: false),
        ],
        verify: (_) {
          expect(
            bloc.effectStream,
            emitsInOrder([
              const SettingsUiEffect.showError('Load error'),
            ]),
          );
        },
      );
    });

    group('SettingsEventUpdateTheme', () {
      blocTest<SettingsBloc, SettingsState>(
        'should update theme mode and save settings',
        build: () {
          when(() => mockSaveSettingsUseCase(any()))
              .thenAnswer((_) async => const Right(unit));
          return bloc;
        },
        seed: () => const SettingsState(
          settings: AppSettings(
            themeMode: ThemeMode.light,
            language: 'en',
            notificationsEnabled: true,
          ),
        ),
        act: (bloc) => bloc.add(const SettingsEvent.updateTheme(ThemeMode.dark)),
        expect: () => [
          const SettingsState(
            settings: AppSettings(
              themeMode: ThemeMode.light,
              language: 'en',
              notificationsEnabled: true,
            ),
            isLoading: true,
          ),
          const SettingsState(
            settings: AppSettings(
              themeMode: ThemeMode.dark,
              language: 'en',
              notificationsEnabled: true,
            ),
            isLoading: false,
          ),
        ],
        verify: (_) {
          verify(
            () => mockSaveSettingsUseCase(
              const AppSettings(
                themeMode: ThemeMode.dark,
                language: 'en',
                notificationsEnabled: true,
              ),
            ),
          ).called(1);
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'should emit success UI effect when theme update succeeds',
        build: () {
          when(() => mockSaveSettingsUseCase(any()))
              .thenAnswer((_) async => const Right(unit));
          return bloc;
        },
        act: (bloc) => bloc.add(const SettingsEvent.updateTheme(ThemeMode.dark)),
        skip: 2,
        verify: (_) {
          expect(
            bloc.effectStream,
            emitsInOrder([
              const SettingsUiEffect.showSuccess('Settings saved successfully'),
            ]),
          );
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'should emit error UI effect when theme update fails',
        build: () {
          when(() => mockSaveSettingsUseCase(any())).thenAnswer(
            (_) async => const Left(CacheFailure(message: 'Save error')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const SettingsEvent.updateTheme(ThemeMode.dark)),
        expect: () => [
          const SettingsState(isLoading: true),
          const SettingsState(isLoading: false),
        ],
        verify: (_) {
          expect(
            bloc.effectStream,
            emitsInOrder([
              const SettingsUiEffect.showError('Save error'),
            ]),
          );
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'should handle all theme mode values',
        build: () {
          when(() => mockSaveSettingsUseCase(any()))
              .thenAnswer((_) async => const Right(unit));
          return bloc;
        },
        act: (bloc) {
          bloc.add(const SettingsEvent.updateTheme(ThemeMode.light));
          bloc.add(const SettingsEvent.updateTheme(ThemeMode.dark));
          bloc.add(const SettingsEvent.updateTheme(ThemeMode.system));
        },
        skip: 6,
        verify: (_) {
          // Verify each theme was saved
          verify(
            () => mockSaveSettingsUseCase(
              const AppSettings(themeMode: ThemeMode.light),
            ),
          ).called(1);
          verify(
            () => mockSaveSettingsUseCase(
              const AppSettings(themeMode: ThemeMode.dark),
            ),
          ).called(1);
          verify(
            () => mockSaveSettingsUseCase(
              const AppSettings(themeMode: ThemeMode.system),
            ),
          ).called(greaterThanOrEqualTo(1));
        },
      );
    });

    group('SettingsEventUpdateLanguage', () {
      blocTest<SettingsBloc, SettingsState>(
        'should update language and save settings',
        build: () {
          when(() => mockSaveSettingsUseCase(any()))
              .thenAnswer((_) async => const Right(unit));
          return bloc;
        },
        seed: () => const SettingsState(
          settings: AppSettings(
            themeMode: ThemeMode.system,
            language: 'en',
            notificationsEnabled: true,
          ),
        ),
        act: (bloc) => bloc.add(const SettingsEvent.updateLanguage('ko')),
        expect: () => [
          const SettingsState(
            settings: AppSettings(
              themeMode: ThemeMode.system,
              language: 'en',
              notificationsEnabled: true,
            ),
            isLoading: true,
          ),
          const SettingsState(
            settings: AppSettings(
              themeMode: ThemeMode.system,
              language: 'ko',
              notificationsEnabled: true,
            ),
            isLoading: false,
          ),
        ],
        verify: (_) {
          verify(
            () => mockSaveSettingsUseCase(
              const AppSettings(
                themeMode: ThemeMode.system,
                language: 'ko',
                notificationsEnabled: true,
              ),
            ),
          ).called(1);
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'should emit success UI effect when language update succeeds',
        build: () {
          when(() => mockSaveSettingsUseCase(any()))
              .thenAnswer((_) async => const Right(unit));
          return bloc;
        },
        act: (bloc) => bloc.add(const SettingsEvent.updateLanguage('es')),
        skip: 2,
        verify: (_) {
          expect(
            bloc.effectStream,
            emitsInOrder([
              const SettingsUiEffect.showSuccess('Settings saved successfully'),
            ]),
          );
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'should emit error UI effect when language update fails',
        build: () {
          when(() => mockSaveSettingsUseCase(any())).thenAnswer(
            (_) async => const Left(CacheFailure(message: 'Save error')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const SettingsEvent.updateLanguage('fr')),
        expect: () => [
          const SettingsState(isLoading: true),
          const SettingsState(isLoading: false),
        ],
        verify: (_) {
          expect(
            bloc.effectStream,
            emitsInOrder([
              const SettingsUiEffect.showError('Save error'),
            ]),
          );
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'should handle multiple language updates',
        build: () {
          when(() => mockSaveSettingsUseCase(any()))
              .thenAnswer((_) async => const Right(unit));
          return bloc;
        },
        act: (bloc) {
          bloc.add(const SettingsEvent.updateLanguage('ko'));
          bloc.add(const SettingsEvent.updateLanguage('es'));
          bloc.add(const SettingsEvent.updateLanguage('fr'));
        },
        skip: 6,
        verify: (_) {
          // Verify each language was saved
          verify(
            () => mockSaveSettingsUseCase(
              const AppSettings(language: 'ko'),
            ),
          ).called(1);
          verify(
            () => mockSaveSettingsUseCase(
              const AppSettings(language: 'es'),
            ),
          ).called(1);
          verify(
            () => mockSaveSettingsUseCase(
              const AppSettings(language: 'fr'),
            ),
          ).called(1);
        },
      );
    });

    group('SettingsEventToggleNotifications', () {
      blocTest<SettingsBloc, SettingsState>(
        'should toggle notifications from true to false and save settings',
        build: () {
          when(() => mockSaveSettingsUseCase(any()))
              .thenAnswer((_) async => const Right(unit));
          return bloc;
        },
        seed: () => const SettingsState(
          settings: AppSettings(
            themeMode: ThemeMode.system,
            language: 'en',
            notificationsEnabled: true,
          ),
        ),
        act: (bloc) => bloc.add(const SettingsEvent.toggleNotifications()),
        expect: () => [
          const SettingsState(
            settings: AppSettings(
              themeMode: ThemeMode.system,
              language: 'en',
              notificationsEnabled: true,
            ),
            isLoading: true,
          ),
          const SettingsState(
            settings: AppSettings(
              themeMode: ThemeMode.system,
              language: 'en',
              notificationsEnabled: false,
            ),
            isLoading: false,
          ),
        ],
        verify: (_) {
          verify(
            () => mockSaveSettingsUseCase(
              const AppSettings(
                themeMode: ThemeMode.system,
                language: 'en',
                notificationsEnabled: false,
              ),
            ),
          ).called(1);
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'should toggle notifications from false to true and save settings',
        build: () {
          when(() => mockSaveSettingsUseCase(any()))
              .thenAnswer((_) async => const Right(unit));
          return bloc;
        },
        seed: () => const SettingsState(
          settings: AppSettings(
            themeMode: ThemeMode.system,
            language: 'en',
            notificationsEnabled: false,
          ),
        ),
        act: (bloc) => bloc.add(const SettingsEvent.toggleNotifications()),
        expect: () => [
          const SettingsState(
            settings: AppSettings(
              themeMode: ThemeMode.system,
              language: 'en',
              notificationsEnabled: false,
            ),
            isLoading: true,
          ),
          const SettingsState(
            settings: AppSettings(
              themeMode: ThemeMode.system,
              language: 'en',
              notificationsEnabled: true,
            ),
            isLoading: false,
          ),
        ],
        verify: (_) {
          verify(
            () => mockSaveSettingsUseCase(
              const AppSettings(
                themeMode: ThemeMode.system,
                language: 'en',
                notificationsEnabled: true,
              ),
            ),
          ).called(1);
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'should emit success UI effect when toggle succeeds',
        build: () {
          when(() => mockSaveSettingsUseCase(any()))
              .thenAnswer((_) async => const Right(unit));
          return bloc;
        },
        act: (bloc) => bloc.add(const SettingsEvent.toggleNotifications()),
        skip: 2,
        verify: (_) {
          expect(
            bloc.effectStream,
            emitsInOrder([
              const SettingsUiEffect.showSuccess('Settings saved successfully'),
            ]),
          );
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'should emit error UI effect when toggle fails',
        build: () {
          when(() => mockSaveSettingsUseCase(any())).thenAnswer(
            (_) async => const Left(CacheFailure(message: 'Save error')),
          );
          return bloc;
        },
        act: (bloc) => bloc.add(const SettingsEvent.toggleNotifications()),
        expect: () => [
          const SettingsState(isLoading: true),
          const SettingsState(isLoading: false),
        ],
        verify: (_) {
          expect(
            bloc.effectStream,
            emitsInOrder([
              const SettingsUiEffect.showError('Save error'),
            ]),
          );
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'should toggle multiple times correctly',
        build: () {
          when(() => mockSaveSettingsUseCase(any()))
              .thenAnswer((_) async => const Right(unit));
          return bloc;
        },
        seed: () => const SettingsState(
          settings: AppSettings(notificationsEnabled: true),
        ),
        act: (bloc) {
          bloc.add(const SettingsEvent.toggleNotifications());
          bloc.add(const SettingsEvent.toggleNotifications());
          bloc.add(const SettingsEvent.toggleNotifications());
        },
        skip: 6,
        verify: (_) {
          // false is saved twice (toggle 1 and toggle 3)
          verify(
            () => mockSaveSettingsUseCase(
              const AppSettings(notificationsEnabled: false),
            ),
          ).called(2);
          // true is saved once (toggle 2)
          verify(
            () => mockSaveSettingsUseCase(
              const AppSettings(notificationsEnabled: true),
            ),
          ).called(1);
        },
      );
    });

    group('Multiple events', () {
      blocTest<SettingsBloc, SettingsState>(
        'should handle multiple different events in sequence',
        build: () {
          when(() => mockSaveSettingsUseCase(any()))
              .thenAnswer((_) async => const Right(unit));
          return bloc;
        },
        act: (bloc) {
          bloc.add(const SettingsEvent.updateTheme(ThemeMode.dark));
          bloc.add(const SettingsEvent.updateLanguage('ko'));
          bloc.add(const SettingsEvent.toggleNotifications());
        },
        skip: 6,
        verify: (_) {
          verify(() => mockSaveSettingsUseCase(any())).called(3);
        },
      );

      blocTest<SettingsBloc, SettingsState>(
        'should maintain state correctly across multiple events',
        build: () {
          when(() => mockSaveSettingsUseCase(any()))
              .thenAnswer((_) async => const Right(unit));
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const SettingsEvent.updateTheme(ThemeMode.dark));
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(const SettingsEvent.updateLanguage('ko'));
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(const SettingsEvent.toggleNotifications());
        },
        wait: const Duration(milliseconds: 500),
        verify: (_) {
          expect(bloc.state.settings.themeMode, ThemeMode.dark);
          expect(bloc.state.settings.language, 'ko');
          expect(bloc.state.settings.notificationsEnabled, false);
        },
      );
    });
  });
}
