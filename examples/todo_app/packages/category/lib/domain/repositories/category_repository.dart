import 'package:core/core.dart';
import '../entities/category.dart';

/// Repository interface for category operations
abstract class CategoryRepository {
  /// Get all categories
  Future<Either<Failure, List<Category>>> getCategories();

  /// Get a category by ID
  Future<Either<Failure, Category>> getCategoryById(String id);

  /// Create a new category
  Future<Either<Failure, Category>> createCategory(Category category);

  /// Update an existing category
  Future<Either<Failure, Category>> updateCategory(Category category);

  /// Delete a category by ID
  Future<Either<Failure, Unit>> deleteCategory(String id);
}
