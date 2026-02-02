part of 'task_edit_bloc.dart';

/// Events for TaskEditBloc
@freezed
sealed class TaskEditEvent with _$TaskEditEvent {
  /// Load task for editing (null taskId = create mode)
  const factory TaskEditEvent.loadTask(String? taskId) = _LoadTask;

  /// Update task title
  const factory TaskEditEvent.updateTitle(String title) = _UpdateTitle;

  /// Update task description
  const factory TaskEditEvent.updateDescription(String description) = _UpdateDescription;

  /// Update task priority
  const factory TaskEditEvent.updatePriority(Priority priority) = _UpdatePriority;

  /// Update task due date
  const factory TaskEditEvent.updateDueDate(DateTime? dueDate) = _UpdateDueDate;

  /// Update task category
  const factory TaskEditEvent.updateCategory(String? categoryId) = _UpdateCategory;

  /// Save task (create or update)
  const factory TaskEditEvent.saveTask() = _SaveTask;
}
