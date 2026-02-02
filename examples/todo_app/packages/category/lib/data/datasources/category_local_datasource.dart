// coverage:ignore-file
import 'package:hive/hive.dart';
import '../models/category_model.dart';

/// Interface for category local data source
abstract class CategoryLocalDataSource {
  /// Get all categories from local storage
  Future<List<CategoryModel>> getCategories();

  /// Get a category by ID from local storage
  Future<CategoryModel?> getCategoryById(String id);

  /// Save a category to local storage
  Future<CategoryModel> saveCategory(CategoryModel category);

  /// Update a category in local storage
  Future<CategoryModel> updateCategory(CategoryModel category);

  /// Delete a category from local storage
  Future<void> deleteCategory(String id);

  /// Check if a category exists
  Future<bool> categoryExists(String id);

  /// Get categories count
  Future<int> getCategoriesCount();
}

/// Hive implementation of CategoryLocalDataSource
class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  static const String _boxName = 'categories';
  final HiveInterface _hive;

  const CategoryLocalDataSourceImpl(this._hive);

  /// Get or open the categories box
  Future<Box<CategoryModel>> get _box async {
    if (!_hive.isBoxOpen(_boxName)) {
      return await _hive.openBox<CategoryModel>(_boxName);
    }
    return _hive.box<CategoryModel>(_boxName);
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final box = await _box;
      final categories = box.values.toList();

      // Sort by creation date
      categories.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return categories;
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  @override
  Future<CategoryModel?> getCategoryById(String id) async {
    try {
      final box = await _box;
      return box.get(id);
    } catch (e) {
      throw Exception('Failed to get category by ID: $e');
    }
  }

  @override
  Future<CategoryModel> saveCategory(CategoryModel category) async {
    try {
      final box = await _box;
      await box.put(category.id, category);

      // Return the saved category
      final savedCategory = box.get(category.id);
      if (savedCategory == null) {
        throw Exception('Failed to retrieve saved category');
      }
      return savedCategory;
    } catch (e) {
      throw Exception('Failed to save category: $e');
    }
  }

  @override
  Future<CategoryModel> updateCategory(CategoryModel category) async {
    try {
      final box = await _box;

      // Check if category exists
      if (!box.containsKey(category.id)) {
        throw Exception('Category not found: ${category.id}');
      }

      await box.put(category.id, category);

      // Return the updated category
      final updatedCategory = box.get(category.id);
      if (updatedCategory == null) {
        throw Exception('Failed to retrieve updated category');
      }
      return updatedCategory;
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      final box = await _box;

      if (!box.containsKey(id)) {
        throw Exception('Category not found: $id');
      }

      await box.delete(id);
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  @override
  Future<bool> categoryExists(String id) async {
    try {
      final box = await _box;
      return box.containsKey(id);
    } catch (e) {
      throw Exception('Failed to check category existence: $e');
    }
  }

  @override
  Future<int> getCategoriesCount() async {
    try {
      final box = await _box;
      return box.length;
    } catch (e) {
      throw Exception('Failed to get categories count: $e');
    }
  }
}
