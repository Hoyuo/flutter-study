part of 'category_bloc.dart';

/// Events for CategoryBloc
@freezed
sealed class CategoryEvent with _$CategoryEvent {
  /// Load all categories
  const factory CategoryEvent.loadCategories() = _LoadCategories;

  /// Create a new category
  const factory CategoryEvent.createCategory({
    required Category category,
  }) = _CreateCategory;

  /// Update an existing category
  const factory CategoryEvent.updateCategory({
    required Category category,
  }) = _UpdateCategory;

  /// Delete a category (will show confirmation)
  const factory CategoryEvent.deleteCategory({
    required String categoryId,
    required String categoryName,
  }) = _DeleteCategory;

  /// Internal event for confirmed deletion
  const factory CategoryEvent.deleteConfirmed({
    required String categoryId,
    required String categoryName,
  }) = _DeleteConfirmed;
}
