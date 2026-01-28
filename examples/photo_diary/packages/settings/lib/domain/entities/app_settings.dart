import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

/// Application settings entity
@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    /// Theme mode (light, dark, or system)
    @Default(ThemeMode.system) ThemeMode themeMode,

    /// Language code (e.g., 'en', 'ko')
    @Default('en') String languageCode,

    /// Whether notifications are enabled
    @Default(true) bool notificationsEnabled,

    /// Whether biometric lock is enabled
    @Default(false) bool biometricLockEnabled,

    /// Reminder time for daily diary entries (null if disabled)
    @TimeOfDayConverter() TimeOfDay? reminderTime,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}

/// Converter for TimeOfDay to/from JSON
class TimeOfDayConverter
    implements JsonConverter<TimeOfDay?, Map<String, dynamic>?> {
  const TimeOfDayConverter();

  @override
  TimeOfDay? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return TimeOfDay(
      hour: json['hour'] as int,
      minute: json['minute'] as int,
    );
  }

  @override
  Map<String, dynamic>? toJson(TimeOfDay? timeOfDay) {
    if (timeOfDay == null) return null;
    return {
      'hour': timeOfDay.hour,
      'minute': timeOfDay.minute,
    };
  }
}
