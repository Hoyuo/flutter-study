part of 'task_edit_bloc.dart';

/// UI effects for TaskEditBloc
@freezed
sealed class TaskEditUiEffect with _$TaskEditUiEffect {
  /// Show success message
  const factory TaskEditUiEffect.showSuccess(String message) = _ShowSuccess;

  /// Show error message
  const factory TaskEditUiEffect.showError(String message) = _ShowError;

  /// Navigate back to previous screen
  const factory TaskEditUiEffect.navigateBack() = _NavigateBack;
}
