import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

import '../entities/entities.dart';

/// Repository interface for app settings operations
abstract class SettingsRepository {
  /// Gets the current app settings
  ///
  /// Returns [AppSettings] on success, [Failure] on error
  Future<Either<Failure, AppSettings>> getSettings();

  /// Updates all app settings
  ///
  /// Returns updated [AppSettings] on success, [Failure] on error
  Future<Either<Failure, AppSettings>> updateSettings(AppSettings settings);

  /// Updates the theme mode
  ///
  /// Returns updated [AppSettings] on success, [Failure] on error
  Future<Either<Failure, AppSettings>> updateThemeMode(ThemeMode themeMode);

  /// Updates the language code
  ///
  /// Returns updated [AppSettings] on success, [Failure] on error
  Future<Either<Failure, AppSettings>> updateLanguage(String languageCode);

  /// Toggles notifications on/off
  ///
  /// Returns updated [AppSettings] on success, [Failure] on error
  Future<Either<Failure, AppSettings>> toggleNotifications(bool enabled);

  /// Toggles biometric lock on/off
  ///
  /// Returns updated [AppSettings] on success, [Failure] on error
  Future<Either<Failure, AppSettings>> toggleBiometricLock(bool enabled);

  /// Updates the reminder time
  ///
  /// Pass null to disable reminders
  /// Returns updated [AppSettings] on success, [Failure] on error
  Future<Either<Failure, AppSettings>> updateReminderTime(TimeOfDay? time);
}
