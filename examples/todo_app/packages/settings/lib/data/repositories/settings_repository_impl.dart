import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  SettingsRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, AppSettings>> getSettings() async {
    try {
      final settings = await localDataSource.getSettings();
      return Right(settings);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to load settings: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveSettings(AppSettings settings) async {
    try {
      await localDataSource.saveSettings(settings);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to save settings: $e'));
    }
  }
}
