part of 'task_bloc.dart';

/// UI effects for TaskBloc
@freezed
sealed class TaskUiEffect with _$TaskUiEffect {
  /// Show success message
  const factory TaskUiEffect.showSuccess(String message) = _ShowSuccess;

  /// Show error message
  const factory TaskUiEffect.showError(String message) = _ShowError;

  /// Show delete confirmation dialog
  const factory TaskUiEffect.confirmDelete({
    required String taskId,
    required String taskTitle,
    required Future<void> Function() onConfirm,
  }) = _ConfirmDelete;
}
