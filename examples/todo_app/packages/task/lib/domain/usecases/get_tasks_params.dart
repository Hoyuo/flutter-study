import 'package:core/core.dart';

/// Sort options for tasks
enum TaskSortBy {
  /// Sort by creation date
  createdAt,

  /// Sort by due date
  dueDate,

  /// Sort by priority level
  priority,

  /// Sort by title alphabetically
  title,
}

/// Parameters for getting tasks with filtering and pagination
class GetTasksParams extends Equatable {
  /// Maximum number of tasks to retrieve
  final int limit;

  /// Number of tasks to skip
  final int offset;

  /// Filter by completion status (null = all tasks)
  final bool? isCompleted;

  /// Filter by priority level (null = all priorities)
  final Priority? priority;

  /// Filter by category ID (null = all categories)
  final String? categoryId;

  /// Sort field
  final TaskSortBy sortBy;

  /// Sort direction (true = ascending, false = descending)
  final bool ascending;

  /// Filter tasks due today only
  final bool? todayOnly;

  const GetTasksParams({
    this.limit = 20,
    this.offset = 0,
    this.isCompleted,
    this.priority,
    this.categoryId,
    this.sortBy = TaskSortBy.createdAt,
    this.ascending = false,
    this.todayOnly,
  });

  /// Create default parameters
  const GetTasksParams.defaults()
      : limit = 20,
        offset = 0,
        isCompleted = null,
        priority = null,
        categoryId = null,
        sortBy = TaskSortBy.createdAt,
        ascending = false,
        todayOnly = null;

  /// Create copy with updated fields
  GetTasksParams copyWith({
    int? limit,
    int? offset,
    bool? isCompleted,
    Priority? priority,
    String? categoryId,
    TaskSortBy? sortBy,
    bool? ascending,
    bool? todayOnly,
  }) {
    return GetTasksParams(
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      categoryId: categoryId ?? this.categoryId,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      todayOnly: todayOnly ?? this.todayOnly,
    );
  }

  /// Clear all filters
  GetTasksParams clearFilters() {
    return GetTasksParams(
      limit: limit,
      offset: 0,
      sortBy: sortBy,
      ascending: ascending,
    );
  }

  @override
  List<Object?> get props => [
        limit,
        offset,
        isCompleted,
        priority,
        categoryId,
        sortBy,
        ascending,
        todayOnly,
      ];
}
