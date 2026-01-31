import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings_event.freezed.dart';

/// 설정 이벤트
@freezed
abstract class SettingsEvent with _$SettingsEvent {
  /// 설정 로드
  const factory SettingsEvent.loadSettings() = LoadSettings;

  /// 테마 모드 업데이트
  const factory SettingsEvent.updateThemeMode(ThemeMode themeMode) =
      UpdateThemeMode;

  /// 언어 업데이트
  const factory SettingsEvent.updateLocale(Locale locale) = UpdateLocale;

  /// 생체인증 토글
  const factory SettingsEvent.toggleBiometricAuth(bool enabled) =
      ToggleBiometricAuth;

  /// 푸시 알림 토글
  const factory SettingsEvent.togglePushNotification(bool enabled) =
      TogglePushNotification;

  /// 설정 초기화
  const factory SettingsEvent.resetSettings() = ResetSettings;
}
