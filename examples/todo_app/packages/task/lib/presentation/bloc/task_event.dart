part of 'task_bloc.dart';

/// Events for TaskBloc
@freezed
sealed class TaskEvent with _$TaskEvent {
  /// Load initial tasks
  const factory TaskEvent.loadTasks() = _LoadTasks;

  /// Load more tasks (pagination)
  const factory TaskEvent.loadMoreTasks() = _LoadMoreTasks;

  /// Search tasks by query
  const factory TaskEvent.searchTasks(String query) = _SearchTasks;

  /// Toggle task completion status
  const factory TaskEvent.toggleCompletion(String taskId) = _ToggleCompletion;

  /// Delete a task
  const factory TaskEvent.deleteTask({
    required String taskId,
    required String taskTitle,
  }) = _DeleteTask;

  /// Apply filters to task list
  const factory TaskEvent.applyFilter({
    bool? isCompleted,
    Priority? priority,
    String? categoryId,
    TaskSortBy? sortBy,
    bool? ascending,
    bool? todayOnly,
  }) = _ApplyFilter;

  /// Clear all filters
  const factory TaskEvent.clearFilter() = _ClearFilter;
}
