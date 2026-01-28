import 'package:core/core.dart';

part 'diary_ui_effect.freezed.dart';

/// Diary Bloc의 UI 이펙트
///
/// 일회성 이벤트로, 스낵바 표시, 네비게이션 등에 사용됩니다.
@freezed
sealed class DiaryUiEffect with _$DiaryUiEffect {
  /// 에러 메시지 표시 이벤트
  ///
  /// [message] 표시할 에러 메시지
  const factory DiaryUiEffect.showError(String message) = DiaryShowError;

  /// 성공 메시지 표시 이벤트
  ///
  /// [message] 표시할 성공 메시지
  const factory DiaryUiEffect.showSuccess(String message) = DiaryShowSuccess;

  /// 상세 화면으로 이동 이벤트
  ///
  /// [entryId] 이동할 일기 ID
  const factory DiaryUiEffect.navigateToDetail(String entryId) =
      DiaryNavigateToDetail;

  /// 뒤로 가기 이벤트
  const factory DiaryUiEffect.navigateBack() = DiaryNavigateBack;

  /// 삭제 확인 다이얼로그 표시 이벤트
  ///
  /// [entryId] 삭제할 일기 ID
  const factory DiaryUiEffect.confirmDelete(String entryId) =
      DiaryConfirmDelete;
}
