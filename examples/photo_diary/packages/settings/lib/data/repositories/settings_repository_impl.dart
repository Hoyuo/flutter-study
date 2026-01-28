import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/datasources.dart';
import '../models/models.dart';

/// Implementation of [SettingsRepository]
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _localDataSource;

  SettingsRepositoryImpl({
    required SettingsLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  @override
  Future<Either<Failure, AppSettings>> getSettings() async {
    return TaskEither.tryCatch(
      () async {
        final model = await _localDataSource.getSettings();
        // Return default settings if nothing is stored
        if (model == null) {
          return const AppSettings();
        }
        return model.toEntity();
      },
      (error, stackTrace) => _handleError(error),
    ).run();
  }

  @override
  Future<Either<Failure, AppSettings>> updateSettings(
      AppSettings settings) async {
    return TaskEither.tryCatch(
      () async {
        final model = AppSettingsModel.fromEntity(settings);
        await _localDataSource.saveSettings(model);
        return settings;
      },
      (error, stackTrace) => _handleError(error),
    ).run();
  }

  @override
  Future<Either<Failure, AppSettings>> updateThemeMode(
      ThemeMode themeMode) async {
    return TaskEither.tryCatch(
      () async {
        final currentSettings = await _getCurrentSettings();
        final updatedSettings = currentSettings.copyWith(themeMode: themeMode);
        final model = AppSettingsModel.fromEntity(updatedSettings);
        await _localDataSource.saveSettings(model);
        return updatedSettings;
      },
      (error, stackTrace) => _handleError(error),
    ).run();
  }

  @override
  Future<Either<Failure, AppSettings>> updateLanguage(
      String languageCode) async {
    return TaskEither.tryCatch(
      () async {
        final currentSettings = await _getCurrentSettings();
        final updatedSettings =
            currentSettings.copyWith(languageCode: languageCode);
        final model = AppSettingsModel.fromEntity(updatedSettings);
        await _localDataSource.saveSettings(model);
        return updatedSettings;
      },
      (error, stackTrace) => _handleError(error),
    ).run();
  }

  @override
  Future<Either<Failure, AppSettings>> toggleNotifications(bool enabled) async {
    return TaskEither.tryCatch(
      () async {
        final currentSettings = await _getCurrentSettings();
        final updatedSettings =
            currentSettings.copyWith(notificationsEnabled: enabled);
        final model = AppSettingsModel.fromEntity(updatedSettings);
        await _localDataSource.saveSettings(model);
        return updatedSettings;
      },
      (error, stackTrace) => _handleError(error),
    ).run();
  }

  @override
  Future<Either<Failure, AppSettings>> toggleBiometricLock(bool enabled) async {
    return TaskEither.tryCatch(
      () async {
        final currentSettings = await _getCurrentSettings();
        final updatedSettings =
            currentSettings.copyWith(biometricLockEnabled: enabled);
        final model = AppSettingsModel.fromEntity(updatedSettings);
        await _localDataSource.saveSettings(model);
        return updatedSettings;
      },
      (error, stackTrace) => _handleError(error),
    ).run();
  }

  @override
  Future<Either<Failure, AppSettings>> updateReminderTime(
      TimeOfDay? time) async {
    return TaskEither.tryCatch(
      () async {
        final currentSettings = await _getCurrentSettings();
        final updatedSettings = currentSettings.copyWith(reminderTime: time);
        final model = AppSettingsModel.fromEntity(updatedSettings);
        await _localDataSource.saveSettings(model);
        return updatedSettings;
      },
      (error, stackTrace) => _handleError(error),
    ).run();
  }

  /// Gets the current settings or returns default if not found
  Future<AppSettings> _getCurrentSettings() async {
    final model = await _localDataSource.getSettings();
    if (model == null) {
      return const AppSettings();
    }
    return model.toEntity();
  }

  /// Handles errors and converts them to [Failure] instances
  Failure _handleError(Object error) {
    return Failure.cache(
      message: 'Failed to access settings storage',
      exception: error is Exception ? error : null,
    );
  }
}
