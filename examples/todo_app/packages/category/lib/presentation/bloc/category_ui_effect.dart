part of 'category_bloc.dart';

/// UI effects for CategoryBloc
@freezed
sealed class CategoryUiEffect with _$CategoryUiEffect {
  /// Show success message
  const factory CategoryUiEffect.showSuccess(String message) = _ShowSuccess;

  /// Show error message
  const factory CategoryUiEffect.showError(String message) = _ShowError;

  /// Show confirmation dialog before deleting
  const factory CategoryUiEffect.confirmDelete({
    required String categoryId,
    required String categoryName,
    required void Function() onConfirmed,
  }) = _ConfirmDelete;
}
