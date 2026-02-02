import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_datasource.dart';
import '../models/category_model.dart';

/// Implementation of CategoryRepository
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDataSource _localDataSource;

  const CategoryRepositoryImpl(this._localDataSource);

  @override
  Future<Either<Failure, List<Category>>> getCategories() async {
    try {
      final models = await _localDataSource.getCategories();
      final entities = models.map((model) => model.toEntity()).toList();
      return Right(entities);
    } on Exception {
      return Left(const Failure.database(
        message: 'Failed to get categories',
        exception: null,
      ));
    } catch (_) {
      return Left(const Failure.unknown(
        message: 'An unexpected error occurred while getting categories',
        error: null,
      ));
    }
  }

  @override
  Future<Either<Failure, Category>> getCategoryById(String id) async {
    try {
      if (id.isEmpty) {
        return Left(const Failure.validation(
          message: 'Category ID cannot be empty',
          field: 'id',
        ));
      }

      final model = await _localDataSource.getCategoryById(id);
      if (model == null) {
        return const Left(Failure.notFound(
          message: 'Category not found',
        ));
      }

      return Right(model.toEntity());
    } on Exception {
      return Left(const Failure.database(
        message: 'Failed to get category by ID',
        exception: null,
      ));
    } catch (_) {
      return Left(const Failure.unknown(
        message: 'An unexpected error occurred while getting category',
        error: null,
      ));
    }
  }

  @override
  Future<Either<Failure, Category>> createCategory(Category category) async {
    try {
      // Validate category
      final validationFailure = _validateCategory(category);
      if (validationFailure != null) {
        return Left(validationFailure);
      }

      // Check if category already exists
      final exists = await _localDataSource.categoryExists(category.id);
      if (exists) {
        return Left(const Failure.validation(
          message: 'Category with this ID already exists',
          field: 'id',
        ));
      }

      final model = CategoryModel.fromEntity(category);
      final savedModel = await _localDataSource.saveCategory(model);
      return Right(savedModel.toEntity());
    } on Exception {
      return Left(const Failure.database(
        message: 'Failed to create category',
        exception: null,
      ));
    } catch (_) {
      return Left(const Failure.unknown(
        message: 'An unexpected error occurred while creating category',
        error: null,
      ));
    }
  }

  @override
  Future<Either<Failure, Category>> updateCategory(Category category) async {
    try {
      // Validate category
      final validationFailure = _validateCategory(category);
      if (validationFailure != null) {
        return Left(validationFailure);
      }

      // Check if category exists
      final exists = await _localDataSource.categoryExists(category.id);
      if (!exists) {
        return const Left(Failure.notFound(
          message: 'Category not found',
        ));
      }

      final model = CategoryModel.fromEntity(category);
      final updatedModel = await _localDataSource.updateCategory(model);
      return Right(updatedModel.toEntity());
    } on Exception {
      return Left(const Failure.database(
        message: 'Failed to update category',
        exception: null,
      ));
    } catch (_) {
      return Left(const Failure.unknown(
        message: 'An unexpected error occurred while updating category',
        error: null,
      ));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteCategory(String id) async {
    try {
      if (id.isEmpty) {
        return Left(const Failure.validation(
          message: 'Category ID cannot be empty',
          field: 'id',
        ));
      }

      // Check if category exists
      final exists = await _localDataSource.categoryExists(id);
      if (!exists) {
        return const Left(Failure.notFound(
          message: 'Category not found',
        ));
      }

      await _localDataSource.deleteCategory(id);
      return const Right(unit);
    } on Exception {
      return Left(const Failure.database(
        message: 'Failed to delete category',
        exception: null,
      ));
    } catch (_) {
      return Left(const Failure.unknown(
        message: 'An unexpected error occurred while deleting category',
        error: null,
      ));
    }
  }

  /// Validate category fields
  Failure? _validateCategory(Category category) {
    if (category.id.isEmpty) {
      return const Failure.validation(
        message: 'Category ID cannot be empty',
        field: 'id',
      );
    }

    if (category.name.trim().isEmpty) {
      return const Failure.validation(
        message: 'Category name cannot be empty',
        field: 'name',
      );
    }

    if (category.name.trim().length > 50) {
      return const Failure.validation(
        message: 'Category name cannot exceed 50 characters',
        field: 'name',
      );
    }

    if (!_isValidHexColor(category.colorHex)) {
      return const Failure.validation(
        message: 'Invalid color hex format',
        field: 'colorHex',
      );
    }

    return null;
  }

  /// Validate hex color format (without # prefix)
  bool _isValidHexColor(String hex) {
    // Should be 6 or 8 characters (RGB or ARGB)
    if (hex.length != 6 && hex.length != 8) {
      return false;
    }

    // Should only contain valid hex characters
    final hexPattern = RegExp(r'^[0-9A-Fa-f]+$');
    return hexPattern.hasMatch(hex);
  }
}
