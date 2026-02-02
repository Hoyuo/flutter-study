part of 'task_bloc.dart';

/// State for TaskBloc
@freezed
abstract class TaskState with _$TaskState {
  const TaskState._();

  const factory TaskState({
    /// List of tasks
    @Default([]) List<Task> tasks,

    /// Loading state
    @Default(false) bool isLoading,

    /// Loading more tasks (pagination)
    @Default(false) bool isLoadingMore,

    /// Has reached end of list
    @Default(false) bool hasReachedEnd,

    /// Current search query
    @Default('') String searchQuery,

    /// Current filter parameters
    @Default(GetTasksParams.defaults()) GetTasksParams currentParams,

    /// Error state
    Failure? failure,
  }) = _TaskState;
}
