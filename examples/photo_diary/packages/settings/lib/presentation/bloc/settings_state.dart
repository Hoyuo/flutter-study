import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/entities.dart';

part 'settings_state.freezed.dart';

/// 설정 상태
@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    /// 현재 설정
    AppSettings? settings,

    /// 로딩 중 여부
    @Default(false) bool isLoading,

    /// 저장 중 여부
    @Default(false) bool isSaving,

    /// 실패 정보
    Failure? failure,
  }) = _SettingsState;

  /// 초기 상태
  factory SettingsState.initial() => const SettingsState(
        isLoading: true,
      );
}
