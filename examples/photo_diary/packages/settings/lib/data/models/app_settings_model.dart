import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/entities.dart';

part 'app_settings_model.freezed.dart';
part 'app_settings_model.g.dart';

/// Application settings data model for persistence
@freezed
abstract class AppSettingsModel with _$AppSettingsModel {
  const AppSettingsModel._();

  const factory AppSettingsModel({
    /// Theme mode (light, dark, or system)
    @Default(ThemeMode.system) @JsonKey(name: 'theme_mode') ThemeMode themeMode,

    /// Language code (e.g., 'en', 'ko')
    @Default('en') @JsonKey(name: 'language_code') String languageCode,

    /// Whether notifications are enabled
    @Default(true) @JsonKey(name: 'notifications_enabled') bool notificationsEnabled,

    /// Whether biometric lock is enabled
    @Default(false) @JsonKey(name: 'biometric_lock_enabled') bool biometricLockEnabled,

    /// Reminder time for daily diary entries (null if disabled)
    @TimeOfDayConverter() @JsonKey(name: 'reminder_time') TimeOfDay? reminderTime,
  }) = _AppSettingsModel;

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsModelFromJson(json);

  /// Converts the model to a domain entity
  AppSettings toEntity() {
    return AppSettings(
      themeMode: themeMode,
      languageCode: languageCode,
      notificationsEnabled: notificationsEnabled,
      biometricLockEnabled: biometricLockEnabled,
      reminderTime: reminderTime,
    );
  }

  /// Creates a model from a domain entity
  factory AppSettingsModel.fromEntity(AppSettings entity) {
    return AppSettingsModel(
      themeMode: entity.themeMode,
      languageCode: entity.languageCode,
      notificationsEnabled: entity.notificationsEnabled,
      biometricLockEnabled: entity.biometricLockEnabled,
      reminderTime: entity.reminderTime,
    );
  }
}
