import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task/task.dart';
import 'package:category/category.dart';
import 'package:settings/settings.dart';

final getIt = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // Register SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // Register DataSources
  getIt.registerLazySingleton<TaskLocalDataSource>(
    () => TaskLocalDataSourceImpl(Hive),
  );
  getIt.registerLazySingleton<CategoryLocalDataSource>(
    () => CategoryLocalDataSourceImpl(Hive),
  );
  getIt.registerLazySingleton<SettingsLocalDataSource>(
    () => SettingsLocalDataSourceImpl(getIt()),
  );

  // Register Repositories
  getIt.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(getIt()),
  );
  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(getIt()),
  );

  // Register Task UseCases
  getIt.registerLazySingleton(() => GetTasksUseCase(getIt()));
  getIt.registerLazySingleton(() => GetTaskByIdUseCase(getIt()));
  getIt.registerLazySingleton(() => CreateTaskUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateTaskUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteTaskUseCase(getIt()));
  getIt.registerLazySingleton(() => ToggleTaskCompletionUseCase(getIt()));
  getIt.registerLazySingleton(() => SearchTasksUseCase(getIt()));
  getIt.registerLazySingleton(() => GetTaskCountByCategoryUseCase(getIt()));

  // Register Category UseCases
  getIt.registerLazySingleton(() => GetCategoriesUseCase(getIt()));
  getIt.registerLazySingleton(() => GetCategoryByIdUseCase(getIt()));
  getIt.registerLazySingleton(() => CreateCategoryUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateCategoryUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteCategoryUseCase(getIt()));

  // Register Settings UseCases
  getIt.registerLazySingleton(() => GetSettingsUseCase(getIt()));
  getIt.registerLazySingleton(() => SaveSettingsUseCase(getIt()));

  // Register BLoCs
  getIt.registerFactory(
    () => TaskBloc(
      getTasksUseCase: getIt(),
      deleteTaskUseCase: getIt(),
      toggleTaskCompletionUseCase: getIt(),
      searchTasksUseCase: getIt(),
    ),
  );

  getIt.registerFactory(
    () => TaskEditBloc(
      getTaskByIdUseCase: getIt(),
      createTaskUseCase: getIt(),
      updateTaskUseCase: getIt(),
    ),
  );

  getIt.registerFactory(
    () => CategoryBloc(
      getCategoriesUseCase: getIt(),
      createCategoryUseCase: getIt(),
      updateCategoryUseCase: getIt(),
      deleteCategoryUseCase: getIt(),
    ),
  );

  getIt.registerFactory(
    () => SettingsBloc(
      getSettingsUseCase: getIt(),
      saveSettingsUseCase: getIt(),
    ),
  );
}
