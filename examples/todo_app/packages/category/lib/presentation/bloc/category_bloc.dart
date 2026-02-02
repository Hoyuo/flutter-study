import 'package:core/core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/category.dart';
import '../../domain/usecases/create_category_usecase.dart';
import '../../domain/usecases/delete_category_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/update_category_usecase.dart';

part 'category_bloc.freezed.dart';
part 'category_event.dart';
part 'category_state.dart';
part 'category_ui_effect.dart';

/// BLoC for managing category operations
class CategoryBloc extends Bloc<CategoryEvent, CategoryState>
    with BlocUiEffectMixin<CategoryUiEffect, CategoryState> {
  final GetCategoriesUseCase _getCategoriesUseCase;
  final CreateCategoryUseCase _createCategoryUseCase;
  final UpdateCategoryUseCase _updateCategoryUseCase;
  final DeleteCategoryUseCase _deleteCategoryUseCase;

  CategoryBloc({
    required GetCategoriesUseCase getCategoriesUseCase,
    required CreateCategoryUseCase createCategoryUseCase,
    required UpdateCategoryUseCase updateCategoryUseCase,
    required DeleteCategoryUseCase deleteCategoryUseCase,
  })  : _getCategoriesUseCase = getCategoriesUseCase,
        _createCategoryUseCase = createCategoryUseCase,
        _updateCategoryUseCase = updateCategoryUseCase,
        _deleteCategoryUseCase = deleteCategoryUseCase,
        super(const CategoryState.initial()) {
    on<CategoryEvent>(
      (event, emit) => event.map(
        loadCategories: (e) => _onLoadCategories(e, emit),
        createCategory: (e) => _onCreateCategory(e, emit),
        updateCategory: (e) => _onUpdateCategory(e, emit),
        deleteCategory: (e) => _onDeleteCategory(e, emit),
        deleteConfirmed: (e) => _onDeleteConfirmed(e, emit),
      ),
    );
  }

  /// Handle loading categories
  Future<void> _onLoadCategories(
    _LoadCategories event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryState.loading(categories: state.categories));

    final result = await _getCategoriesUseCase(const NoParams());

    result.fold(
      (failure) {
        emit(CategoryState.error(
          categories: state.categories,
          failure: failure,
        ));
        emitUiEffect(CategoryUiEffect.showError(
          _getFailureMessage(failure),
        ));
      },
      (categories) {
        emit(CategoryState.loaded(categories: categories));
      },
    );
  }

  /// Handle creating a category
  Future<void> _onCreateCategory(
    _CreateCategory event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryState.loading(categories: state.categories));

    final result = await _createCategoryUseCase(
      CreateCategoryParams(event.category),
    );

    result.fold(
      (failure) {
        emit(CategoryState.error(
          categories: state.categories,
          failure: failure,
        ));
        emitUiEffect(CategoryUiEffect.showError(
          _getFailureMessage(failure),
        ));
      },
      (category) {
        // Reload categories to get updated list
        add(const CategoryEvent.loadCategories());
        emitUiEffect(CategoryUiEffect.showSuccess(
          'Category "${category.name}" created successfully',
        ));
      },
    );
  }

  /// Handle updating a category
  Future<void> _onUpdateCategory(
    _UpdateCategory event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryState.loading(categories: state.categories));

    final result = await _updateCategoryUseCase(
      UpdateCategoryParams(event.category),
    );

    result.fold(
      (failure) {
        emit(CategoryState.error(
          categories: state.categories,
          failure: failure,
        ));
        emitUiEffect(CategoryUiEffect.showError(
          _getFailureMessage(failure),
        ));
      },
      (category) {
        // Reload categories to get updated list
        add(const CategoryEvent.loadCategories());
        emitUiEffect(CategoryUiEffect.showSuccess(
          'Category "${category.name}" updated successfully',
        ));
      },
    );
  }

  /// Handle deleting a category
  Future<void> _onDeleteCategory(
    _DeleteCategory event,
    Emitter<CategoryState> emit,
  ) async {
    // Show confirmation dialog
    emitUiEffect(CategoryUiEffect.confirmDelete(
      categoryId: event.categoryId,
      categoryName: event.categoryName,
      onConfirmed: () {
        add(CategoryEvent.deleteConfirmed(
          categoryId: event.categoryId,
          categoryName: event.categoryName,
        ));
      },
    ));
  }

  /// Handle confirmed deletion
  Future<void> _onDeleteConfirmed(
    _DeleteConfirmed event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryState.loading(categories: state.categories));

    final result = await _deleteCategoryUseCase(
      DeleteCategoryParams(event.categoryId),
    );

    result.fold(
      (failure) {
        emit(CategoryState.error(
          categories: state.categories,
          failure: failure,
        ));
        emitUiEffect(CategoryUiEffect.showError(
          _getFailureMessage(failure),
        ));
      },
      (_) {
        // Reload categories to get updated list
        add(const CategoryEvent.loadCategories());
        emitUiEffect(CategoryUiEffect.showSuccess(
          'Category "${event.categoryName}" deleted successfully',
        ));
      },
    );
  }

  /// Convert failure to user-friendly message
  String _getFailureMessage(Failure failure) {
    return switch (failure) {
      DatabaseFailure(:final message) => message,
      ValidationFailure(:final message) => message,
      NotFoundFailure(:final message) => message,
      CacheFailure(:final message) => message,
      UnknownFailure() => 'An unexpected error occurred',
      _ => 'An error occurred',
    };
  }
}
