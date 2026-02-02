# Category Package

Category domain package for the TODO app, implementing Clean Architecture with Hive database.

## Architecture

### Domain Layer
- **Entities**: `Category` - Freezed immutable entity representing a task category
- **Repositories**: `CategoryRepository` - Interface for category data operations
- **Use Cases**:
  - `GetCategoriesUseCase` - Retrieve all categories
  - `GetCategoryByIdUseCase` - Get a specific category by ID
  - `CreateCategoryUseCase` - Create a new category
  - `UpdateCategoryUseCase` - Update an existing category
  - `DeleteCategoryUseCase` - Delete a category

### Data Layer
- **Models**: `CategoryModel` - Hive model with manual TypeAdapter
- **Data Sources**: `CategoryLocalDataSource` - Hive-based local storage
- **Repository Implementation**: `CategoryRepositoryImpl` - Full implementation with validation

### Presentation Layer
- **BLoC**: `CategoryBloc` with BlocUiEffectMixin
  - Events: loadCategories, createCategory, updateCategory, deleteCategory
  - States: initial, loading, loaded, error
  - UI Effects: showSuccess, showError, confirmDelete

## Features

- Complete CRUD operations for categories
- Input validation (name length, color format)
- Error handling with typed Failure classes
- Hive database with manual TypeAdapter (no code generation conflicts)
- BLoC state management with UI effects
- Freezed for immutability

## Database

Uses Hive with manual TypeAdapter implementation to avoid freezed 3.x compatibility issues with hive_generator.

## Usage

```dart
import 'package:category/category.dart';

// Initialize Hive adapter
Hive.registerAdapter(CategoryModelAdapter());

// Create repository
final dataSource = CategoryLocalDataSourceImpl(Hive);
final repository = CategoryRepositoryImpl(dataSource);

// Create use cases
final getCategoriesUseCase = GetCategoriesUseCase(repository);
// ... other use cases

// Create BLoC
final categoryBloc = CategoryBloc(
  getCategoriesUseCase: getCategoriesUseCase,
  createCategoryUseCase: createCategoryUseCase,
  updateCategoryUseCase: updateCategoryUseCase,
  deleteCategoryUseCase: deleteCategoryUseCase,
);
```

## Notes

- Replaced Isar with Hive due to freezed 3.x compatibility issues
- Manual TypeAdapter implementation avoids hive_generator conflicts
- VoidCallback replaced with `void Function()` to avoid foundation.dart conflicts
