part of 'task_edit_bloc.dart';

/// State for TaskEditBloc
@freezed
abstract class TaskEditState with _$TaskEditState {
  const TaskEditState._();

  const factory TaskEditState({
    /// Original task being edited (null for create mode)
    Task? task,

    /// Current title value
    @Default('') String title,

    /// Current description value
    @Default('') String description,

    /// Current priority value
    @Default(Priority.medium) Priority priority,

    /// Current due date value
    DateTime? dueDate,

    /// Current category ID value
    String? categoryId,

    /// Loading state (when loading task)
    @Default(false) bool isLoading,

    /// Saving state (when creating/updating)
    @Default(false) bool isSaving,

    /// Edit mode flag (true = edit, false = create)
    @Default(false) bool isEditMode,

    /// Error state
    Failure? failure,
  }) = _TaskEditState;
}
