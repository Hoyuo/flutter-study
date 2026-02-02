# TODO App Architecture Document

## Overview

photo_diary 예제와 동일한 **Clean Architecture** 패턴으로 구현하는 TODO 앱입니다.

- **데이터 저장소**: Isar (로컬 NoSQL DB, Firebase 미사용)
- **기능**: CRUD + 카테고리/태그 + 우선순위/마감일
- **패턴**: Clean Architecture + BLoC + Either<Failure, T>

---

## 1. Project Structure

```
examples/todo_app/
├── .fvmrc
├── .gitignore
├── analysis_options.yaml
├── pubspec.yaml                 # Melos workspace root
├── README.md
│
├── apps/
│   └── todo_app/
│       ├── pubspec.yaml
│       ├── lib/
│       │   ├── main.dart
│       │   ├── app.dart
│       │   └── core/
│       │       ├── di/
│       │       │   └── injection.dart      # GetIt DI configuration
│       │       └── router/
│       │           └── app_router.dart     # GoRouter configuration
│       └── assets/
│           └── translations/
│               ├── en-US.json
│               └── ko-KR.json
│
└── packages/
    ├── core/                    # Shared utilities
    │   └── lib/
    │       ├── core.dart        # Barrel file
    │       ├── bloc/            # BlocUiEffectMixin
    │       ├── error/           # Failure types
    │       ├── types/           # UseCase, Priority enum
    │       ├── theme/           # AppTheme, AppColors
    │       ├── extensions/      # DateTime, String extensions
    │       └── utils/           # Logger, Validators
    │
    ├── task/                    # Task feature package
    │   └── lib/
    │       ├── task.dart
    │       ├── domain/
    │       │   ├── entities/    # Task entity (Freezed)
    │       │   ├── repositories/# TaskRepository interface
    │       │   └── usecases/    # CRUD, Toggle, Search, Filter
    │       ├── data/
    │       │   ├── models/      # TaskModel (Isar collection)
    │       │   ├── datasources/ # TaskLocalDataSource
    │       │   └── repositories/# TaskRepositoryImpl
    │       └── presentation/
    │           ├── bloc/        # TaskBloc, TaskEditBloc
    │           ├── pages/       # TaskListPage, TaskEditPage
    │           └── widgets/     # TaskCard, PriorityBadge
    │
    ├── category/                # Category feature package
    │   └── lib/
    │       ├── category.dart
    │       ├── domain/
    │       │   ├── entities/    # Category entity
    │       │   ├── repositories/# CategoryRepository interface
    │       │   └── usecases/    # CRUD
    │       ├── data/
    │       │   ├── models/      # CategoryModel (Isar collection)
    │       │   ├── datasources/ # CategoryLocalDataSource
    │       │   └── repositories/# CategoryRepositoryImpl
    │       └── presentation/
    │           ├── bloc/        # CategoryBloc
    │           ├── pages/       # CategoryManagementPage
    │           └── widgets/     # CategoryTile, CategoryPicker
    │
    └── settings/                # Settings feature package
        └── lib/
            ├── settings.dart
            ├── domain/          # AppSettings entity, UseCases
            ├── data/            # SharedPreferences datasource
            └── presentation/    # SettingsBloc, SettingsPage
```

---

## 2. Domain Models

### 2.1 Task Entity

```dart
@freezed
abstract class Task with _$Task {
  const factory Task({
    required String id,
    required String title,
    @Default('') String description,
    @Default(false) bool isCompleted,
    @Default(Priority.medium) Priority priority,
    DateTime? dueDate,
    String? categoryId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Task;
}
```

### 2.2 Category Entity

```dart
@freezed
abstract class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    required String colorHex,
    String? iconName,
    required DateTime createdAt,
  }) = _Category;
}
```

### 2.3 Priority Enum

```dart
enum Priority {
  high(3, 'High', 'FF0000'),
  medium(2, 'Medium', 'FFA500'),
  low(1, 'Low', '00FF00');

  const Priority(this.value, this.label, this.colorHex);

  final int value;
  final String label;
  final String colorHex;
}
```

---

## 3. Isar Schema

### 3.1 TaskModel (Isar Collection)

```dart
@collection
class TaskModel {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  @Index(type: IndexType.value)
  late String title;

  late String description;

  @Index()
  late bool isCompleted;

  @Index()
  late int priority;

  @Index()
  DateTime? dueDate;

  @Index()
  String? categoryId;

  @Index()
  late DateTime createdAt;

  late DateTime updatedAt;
}
```

### 3.2 CategoryModel (Isar Collection)

```dart
@collection
class CategoryModel {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  @Index(type: IndexType.value)
  late String name;

  late String colorHex;
  String? iconName;
  late DateTime createdAt;
}
```

### 3.3 Index Design

| Collection | Field | Index Type | Purpose |
|------------|-------|------------|---------|
| TaskModel | id | unique | Primary key |
| TaskModel | title | value | Text search |
| TaskModel | isCompleted | normal | Filter by status |
| TaskModel | priority | normal | Filter by priority |
| TaskModel | dueDate | normal | Filter/sort by date |
| TaskModel | categoryId | normal | Filter by category |
| TaskModel | createdAt | normal | Sort by creation |
| CategoryModel | id | unique | Primary key |
| CategoryModel | name | value | Text search |

---

## 4. UseCase List

### 4.1 Task UseCases

| UseCase | Params | Return | Description |
|---------|--------|--------|-------------|
| `GetTasksUseCase` | `GetTasksParams` | `List<Task>` | Paginated list with filters |
| `GetTaskByIdUseCase` | `String` | `Task` | Single task by ID |
| `CreateTaskUseCase` | `Task` | `Task` | Create new task |
| `UpdateTaskUseCase` | `Task` | `Task` | Update existing task |
| `DeleteTaskUseCase` | `String` | `Unit` | Delete task by ID |
| `ToggleTaskCompletionUseCase` | `String` | `Task` | Toggle completion |
| `SearchTasksUseCase` | `SearchTasksParams` | `List<Task>` | Search by keyword |

### 4.2 GetTasksParams

```dart
class GetTasksParams {
  final int limit;
  final int offset;
  final bool? isCompleted;
  final Priority? priority;
  final String? categoryId;
  final TaskSortBy sortBy;
  final bool ascending;
}

enum TaskSortBy { createdAt, dueDate, priority, title }
```

### 4.3 Category UseCases

| UseCase | Params | Return | Description |
|---------|--------|--------|-------------|
| `GetCategoriesUseCase` | `NoParams` | `List<Category>` | Get all categories |
| `CreateCategoryUseCase` | `Category` | `Category` | Create category |
| `UpdateCategoryUseCase` | `Category` | `Category` | Update category |
| `DeleteCategoryUseCase` | `String` | `Unit` | Delete category |

---

## 5. BLoC Design

### 5.1 TaskBloc (List, Filter, Search)

```dart
// Events
@freezed
abstract class TaskEvent with _$TaskEvent {
  const factory TaskEvent.loadTasks({...}) = LoadTasks;
  const factory TaskEvent.loadMoreTasks() = LoadMoreTasks;
  const factory TaskEvent.searchTasks(String query) = SearchTasks;
  const factory TaskEvent.toggleCompletion(String taskId) = ToggleTaskCompletion;
  const factory TaskEvent.deleteTask(String taskId) = DeleteTask;
  const factory TaskEvent.applyFilter(TaskFilter filter) = ApplyFilter;
}

// State
@freezed
abstract class TaskState with _$TaskState {
  const factory TaskState({
    @Default([]) List<Task> tasks,
    @Default(false) bool isLoading,
    @Default(false) bool hasReachedEnd,
    String? searchQuery,
    TaskFilter? filter,
    @Default(TaskSortBy.createdAt) TaskSortBy sortBy,
    Failure? failure,
  }) = _TaskState;
}

// UI Effects
@freezed
abstract class TaskUiEffect with _$TaskUiEffect {
  const factory TaskUiEffect.showError(String message) = TaskShowError;
  const factory TaskUiEffect.showSuccess(String message) = TaskShowSuccess;
  const factory TaskUiEffect.confirmDelete(String taskId) = TaskConfirmDelete;
}
```

### 5.2 TaskEditBloc (Create/Update)

```dart
// Events
@freezed
abstract class TaskEditEvent with _$TaskEditEvent {
  const factory TaskEditEvent.loadTask(String taskId) = LoadTaskForEdit;
  const factory TaskEditEvent.updateTitle(String title) = UpdateTitle;
  const factory TaskEditEvent.updateDescription(String desc) = UpdateDescription;
  const factory TaskEditEvent.updatePriority(Priority priority) = UpdatePriority;
  const factory TaskEditEvent.updateDueDate(DateTime? date) = UpdateDueDate;
  const factory TaskEditEvent.updateCategory(String? categoryId) = UpdateCategory;
  const factory TaskEditEvent.saveTask() = SaveTask;
}

// State
@freezed
abstract class TaskEditState with _$TaskEditState {
  const factory TaskEditState({
    Task? task,
    @Default('') String title,
    @Default('') String description,
    @Default(Priority.medium) Priority priority,
    DateTime? dueDate,
    String? categoryId,
    @Default(false) bool isLoading,
    @Default(false) bool isSaving,
    @Default(false) bool isEditMode,
    Failure? failure,
  }) = _TaskEditState;
}

// UI Effects
@freezed
abstract class TaskEditUiEffect with _$TaskEditUiEffect {
  const factory TaskEditUiEffect.navigateBack() = TaskEditNavigateBack;
  const factory TaskEditUiEffect.showError(String message) = TaskEditShowError;
  const factory TaskEditUiEffect.showSuccess(String message) = TaskEditShowSuccess;
}
```

### 5.3 CategoryBloc

```dart
// Events
@freezed
abstract class CategoryEvent with _$CategoryEvent {
  const factory CategoryEvent.loadCategories() = LoadCategories;
  const factory CategoryEvent.createCategory(Category category) = CreateCategory;
  const factory CategoryEvent.updateCategory(Category category) = UpdateCategory;
  const factory CategoryEvent.deleteCategory(String categoryId) = DeleteCategory;
}

// State
@freezed
abstract class CategoryState with _$CategoryState {
  const factory CategoryState({
    @Default([]) List<Category> categories,
    @Default(false) bool isLoading,
    Failure? failure,
  }) = _CategoryState;
}
```

---

## 6. UI Screens

### 6.1 Screen List

| Screen | Route | Description |
|--------|-------|-------------|
| TaskListPage | `/tasks` | Home - task list with filters |
| TaskEditPage | `/tasks/new` | Create new task |
| TaskEditPage | `/tasks/:id/edit` | Edit existing task |
| CategoryManagementPage | `/categories` | Category CRUD |
| SettingsPage | `/settings` | Theme settings |

### 6.2 Navigation Flow

```
/ (root) -> /tasks (redirect)
    │
    ├── /tasks (TaskListPage)
    │       │
    │       ├── /tasks/new (TaskEditPage - create)
    │       └── /tasks/:id/edit (TaskEditPage - edit)
    │
    ├── /categories (CategoryManagementPage)
    │
    └── /settings (SettingsPage)
```

### 6.3 GoRouter Configuration

```dart
GoRouter(
  initialLocation: '/tasks',
  routes: [
    GoRoute(
      path: '/tasks',
      builder: (_, __) => const TaskListPage(),
      routes: [
        GoRoute(path: 'new', builder: (_, __) => const TaskEditPage()),
        GoRoute(
          path: ':id/edit',
          builder: (_, state) => TaskEditPage(taskId: state.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(path: '/categories', builder: (_, __) => const CategoryManagementPage()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
  ],
)
```

---

## 7. Dependencies

### 7.1 Root Workspace (pubspec.yaml)

```yaml
name: todo_app_workspace
publish_to: none

environment:
  sdk: '>=3.8.0 <4.0.0'

workspace:
  - apps/todo_app
  - packages/core
  - packages/task
  - packages/category
  - packages/settings

dev_dependencies:
  melos: ^7.4.0

melos:
  name: todo_app_workspace
  packages:
    - apps/*
    - packages/*
  scripts:
    clean:
      run: melos exec -- "flutter clean"
    get:
      run: melos exec -- "flutter pub get"
    build_runner:
      run: melos exec --order-dependents --concurrency=1 --depends-on="build_runner" -- "dart run build_runner build --delete-conflicting-outputs"
    test:
      run: melos exec -- "flutter test"
```

### 7.2 Key Dependencies

```yaml
# State Management
flutter_bloc: ^9.0.0
equatable: ^2.0.5

# Database (Isar)
isar: ^4.0.0-dev.14
isar_flutter_libs: ^4.0.0-dev.14

# Code Generation
freezed: ^3.2.3
freezed_annotation: ^3.1.0
json_serializable: ^6.8.0
json_annotation: ^4.9.0
isar_generator: ^4.0.0-dev.14
build_runner: ^2.4.13

# Functional Programming
fpdart: ^1.1.0

# DI & Routing
get_it: ^9.2.0
go_router: ^17.0.0

# Utilities
uuid: ^4.5.1
intl: ^0.20.2
shared_preferences: ^2.5.0
logger: ^2.5.0

# Testing
flutter_test:
bloc_test: ^10.0.0
mocktail: ^1.0.4
```

---

## 8. Implementation Phases

### Phase 1: Core Package
- [ ] Failure sealed class
- [ ] UseCase base class
- [ ] Priority enum
- [ ] BlocUiEffectMixin
- [ ] AppTheme, AppColors
- [ ] DateTime/String extensions

### Phase 2: Category Package
- [ ] Category entity (Freezed)
- [ ] CategoryModel (Isar)
- [ ] CategoryRepository interface + impl
- [ ] CRUD UseCases
- [ ] CategoryBloc
- [ ] CategoryManagementPage
- [ ] Unit tests

### Phase 3: Task Package
- [ ] Task entity (Freezed)
- [ ] TaskModel (Isar with indexes)
- [ ] TaskRepository interface + impl
- [ ] UseCases (CRUD, Toggle, Search, Filter)
- [ ] TaskBloc, TaskEditBloc
- [ ] TaskListPage, TaskEditPage
- [ ] TaskCard, PriorityBadge widgets
- [ ] Unit tests

### Phase 4: Settings Package
- [ ] AppSettings entity
- [ ] SettingsRepository (SharedPreferences)
- [ ] SettingsBloc
- [ ] SettingsPage
- [ ] Unit tests

### Phase 5: App Shell
- [ ] Isar initialization
- [ ] GetIt DI configuration
- [ ] GoRouter setup
- [ ] main.dart, app.dart
- [ ] Integration tests

### Phase 6: Testing & Polish
- [ ] 100% test coverage
- [ ] UI polish
- [ ] README documentation

---

## 9. File Count Estimate

| Package | Files |
|---------|-------|
| Core | ~15 |
| Task | ~25 |
| Category | ~15 |
| Settings | ~10 |
| App | ~5 |
| Tests | ~30 |
| **Total** | **~100** |

---

## 10. Reference Files (photo_diary)

패턴 참고용 파일들:
- `packages/core/lib/bloc/bloc_ui_effect_mixin.dart`
- `packages/core/lib/types/usecase.dart`
- `packages/core/lib/error/failure.dart`
- `packages/diary/lib/presentation/bloc/diary_bloc.dart`
- `apps/photo_diary/lib/core/di/injection.dart`
- `apps/photo_diary/lib/core/router/app_router.dart`
