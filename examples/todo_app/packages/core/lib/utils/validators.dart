/// Validation utilities
class Validators {
  // coverage:ignore-start
  Validators._();
  // coverage:ignore-end

  /// Validate task title
  static String? validateTaskTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }
    if (value.length > 100) {
      return 'Title must be less than 100 characters';
    }
    return null;
  }

  /// Validate category name
  static String? validateCategoryName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Category name is required';
    }
    if (value.length > 50) {
      return 'Category name must be less than 50 characters';
    }
    return null;
  }

  /// Validate description
  static String? validateDescription(String? value) {
    if (value != null && value.length > 500) {
      return 'Description must be less than 500 characters';
    }
    return null;
  }
}
