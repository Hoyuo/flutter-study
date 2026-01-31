import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core package
import 'package:core/core.dart';
import 'package:core/services/services.dart';

// Auth package
import 'package:auth/auth.dart';
import 'package:auth/data/datasources/auth_remote_datasource_impl.dart';

// Diary package
import 'package:diary/diary.dart';
import 'package:diary/data/datasources/diary_remote_datasource_impl.dart';
import 'package:diary/data/datasources/image_storage_datasource_impl.dart';

// Settings package
import 'package:settings/settings.dart';
import 'package:settings/data/datasources/settings_local_datasource_impl.dart';

// App-level dependencies
import '../lifecycle/app_lifecycle_handler.dart';
import '../router/app_router.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Register external dependencies first
  await _registerExternalDependencies();

  // Register core services
  _registerCoreServices();

  // Register auth dependencies
  _registerAuthDependencies();

  // Register diary dependencies
  _registerDiaryDependencies();

  // Register settings dependencies
  _registerSettingsDependencies();

  // Register app-level dependencies
  _registerAppDependencies();
}

Future<void> _registerExternalDependencies() async {
  // Firebase instances
  getIt.registerLazySingleton<fb_auth.FirebaseAuth>(
    () => fb_auth.FirebaseAuth.instance,
  );
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );
  getIt.registerLazySingleton<FirebaseStorage>(
    () => FirebaseStorage.instance,
  );

  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
}

void _registerCoreServices() {
  // Core services
  getIt.registerLazySingleton<AppLifecycleService>(
    () => AppLifecycleServiceImpl(),
  );
  getIt.registerLazySingleton<BiometricService>(
    () => BiometricServiceImpl(),
  );
  getIt.registerLazySingleton<AnalyticsService>(
    () => FirebaseAnalyticsServiceImpl(),
  );
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(),
  );
  getIt.registerLazySingleton<CrashlyticsService>(
    () => FirebaseCrashlyticsServiceImpl(),
  );
  getIt.registerLazySingleton<ImageService>(
    () => ImageServiceImpl(),
  );
  getIt.registerLazySingleton<CurrentUserService>(
    () => CurrentUserServiceImpl(),
  );
}

void _registerAuthDependencies() {
  // Auth DataSource
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => FirebaseAuthRemoteDataSource(
      firebaseAuth: getIt<fb_auth.FirebaseAuth>(),
    ),
  );

  // Auth Repository
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
    ),
  );

  // Auth UseCases
  getIt.registerLazySingleton<SignInWithEmailUseCase>(
    () => SignInWithEmailUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<SignUpUseCase>(
    () => SignUpUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<SignOutUseCase>(
    () => SignOutUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<GetCurrentUserUseCase>(
    () => GetCurrentUserUseCase(getIt<AuthRepository>()),
  );

  // Auth Bloc
  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      signInUseCase: getIt<SignInWithEmailUseCase>(),
      signUpUseCase: getIt<SignUpUseCase>(),
      signOutUseCase: getIt<SignOutUseCase>(),
      getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
    ),
  );
}

void _registerDiaryDependencies() {
  // Diary DataSources
  getIt.registerLazySingleton<DiaryRemoteDataSource>(
    () => FirestoreDiaryRemoteDataSource(
      firestore: getIt<FirebaseFirestore>(),
    ),
  );
  getIt.registerLazySingleton<ImageStorageDataSource>(
    () => FirebaseStorageImageDataSource(
      storage: getIt<FirebaseStorage>(),
    ),
  );

  // Diary Repository
  getIt.registerLazySingleton<DiaryRepository>(
    () => DiaryRepositoryImpl(
      remoteDataSource: getIt<DiaryRemoteDataSource>(),
      imageStorageDataSource: getIt<ImageStorageDataSource>(),
      currentUserService: getIt<CurrentUserService>(),
    ),
  );

  // Diary UseCases
  getIt.registerLazySingleton<GetDiariesUseCase>(
    () => GetDiariesUseCase(getIt<DiaryRepository>()),
  );
  getIt.registerLazySingleton<GetDiaryByIdUseCase>(
    () => GetDiaryByIdUseCase(getIt<DiaryRepository>()),
  );
  getIt.registerLazySingleton<CreateDiaryUseCase>(
    () => CreateDiaryUseCase(getIt<DiaryRepository>()),
  );
  getIt.registerLazySingleton<UpdateDiaryUseCase>(
    () => UpdateDiaryUseCase(getIt<DiaryRepository>()),
  );
  getIt.registerLazySingleton<DeleteDiaryUseCase>(
    () => DeleteDiaryUseCase(getIt<DiaryRepository>()),
  );
  getIt.registerLazySingleton<SearchDiariesUseCase>(
    () => SearchDiariesUseCase(getIt<DiaryRepository>()),
  );

  // Diary Bloc
  getIt.registerFactory<DiaryBloc>(
    () => DiaryBloc(
      getDiariesUseCase: getIt<GetDiariesUseCase>(),
      getDiaryByIdUseCase: getIt<GetDiaryByIdUseCase>(),
      createDiaryUseCase: getIt<CreateDiaryUseCase>(),
      updateDiaryUseCase: getIt<UpdateDiaryUseCase>(),
      deleteDiaryUseCase: getIt<DeleteDiaryUseCase>(),
      searchDiariesUseCase: getIt<SearchDiariesUseCase>(),
    ),
  );
}

void _registerSettingsDependencies() {
  // Settings DataSource
  getIt.registerLazySingleton<SettingsLocalDataSource>(
    () => SharedPreferencesSettingsDataSourceImpl(getIt<SharedPreferences>()),
  );

  // Settings Repository
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(
      localDataSource: getIt<SettingsLocalDataSource>(),
    ),
  );

  // Settings UseCases
  getIt.registerLazySingleton<GetSettingsUseCase>(
    () => GetSettingsUseCase(getIt<SettingsRepository>()),
  );
  getIt.registerLazySingleton<UpdateSettingsUseCase>(
    () => UpdateSettingsUseCase(getIt<SettingsRepository>()),
  );

  // Settings Bloc
  getIt.registerFactory<SettingsBloc>(
    () => SettingsBloc(
      getSettingsUseCase: getIt<GetSettingsUseCase>(),
      updateSettingsUseCase: getIt<UpdateSettingsUseCase>(),
    ),
  );
}

void _registerAppDependencies() {
  // App Lifecycle Handler
  getIt.registerSingleton<AppLifecycleHandler>(
    AppLifecycleHandler(
      lifecycleService: getIt<AppLifecycleService>(),
      biometricService: getIt<BiometricService>(),
      analyticsService: getIt<AnalyticsService>(),
      storageService: getIt<SecureStorageService>(),
    ),
  );

  // App Router
  getIt.registerSingleton<AppRouter>(
    AppRouter(
      getIt<AuthBloc>(),
      getIt<AnalyticsService>(),
    ),
  );
}
