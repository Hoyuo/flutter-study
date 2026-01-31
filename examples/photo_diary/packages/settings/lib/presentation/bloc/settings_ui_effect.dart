import 'package:core/core.dart';

part 'settings_ui_effect.freezed.dart';

/// Settings Bloc의 UI 이펙트
///
/// 일회성 이벤트로, 스낵바 표시 등에 사용됩니다.
@freezed
abstract class SettingsUiEffect with _$SettingsUiEffect {
  /// 에러 메시지 표시 이벤트
  ///
  /// [message] 표시할 에러 메시지
  const factory SettingsUiEffect.showError(String message) = SettingsShowError;

  /// 성공 메시지 표시 이벤트
  ///
  /// [message] 표시할 성공 메시지
  const factory SettingsUiEffect.showSuccess(String message) = SettingsShowSuccess;
}
