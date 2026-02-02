import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/task.dart';
import '../../domain/usecases/get_task_by_id_usecase.dart';
import '../../domain/usecases/create_task_usecase.dart';
import '../../domain/usecases/update_task_usecase.dart';

part 'task_edit_bloc.freezed.dart';
part 'task_edit_event.dart';
part 'task_edit_state.dart';
part 'task_edit_ui_effect.dart';

/// BLoC for creating and editing a single task
class TaskEditBloc extends Bloc<TaskEditEvent, TaskEditState>
    with BlocUiEffectMixin<TaskEditUiEffect, TaskEditState> {
  final GetTaskByIdUseCase _getTaskByIdUseCase;
  final CreateTaskUseCase _createTaskUseCase;
  final UpdateTaskUseCase _updateTaskUseCase;
  final Uuid _uuid;

  TaskEditBloc({
    required GetTaskByIdUseCase getTaskByIdUseCase,
    required CreateTaskUseCase createTaskUseCase,
    required UpdateTaskUseCase updateTaskUseCase,
    Uuid? uuid,
  })  : _getTaskByIdUseCase = getTaskByIdUseCase,
        _createTaskUseCase = createTaskUseCase,
        _updateTaskUseCase = updateTaskUseCase,
        _uuid = uuid ?? const Uuid(),
        super(const TaskEditState()) {
    on<TaskEditEvent>(_onEvent);
  }

  Future<void> _onEvent(
    TaskEditEvent event,
    Emitter<TaskEditState> emit,
  ) async {
    await event.map(
      loadTask: (e) => _onLoadTask(e, emit),
      updateTitle: (e) => _onUpdateTitle(e, emit),
      updateDescription: (e) => _onUpdateDescription(e, emit),
      updatePriority: (e) => _onUpdatePriority(e, emit),
      updateDueDate: (e) => _onUpdateDueDate(e, emit),
      updateCategory: (e) => _onUpdateCategory(e, emit),
      saveTask: (e) => _onSaveTask(e, emit),
    );
  }

  Future<void> _onLoadTask(
    _LoadTask event,
    Emitter<TaskEditState> emit,
  ) async {
    if (event.taskId == null) {
      // Create mode - initialize with empty task
      emit(state.copyWith(
        isEditMode: false,
        isLoading: false,
      ));
      return;
    }

    // Edit mode - load existing task
    emit(state.copyWith(isLoading: true));

    final result = await _getTaskByIdUseCase(event.taskId!);

    result.fold(
      (failure) {
        emit(state.copyWith(
          isLoading: false,
          failure: failure,
        ));
        emitUiEffect(TaskEditUiEffect.showError(failure.message));
      },
      (task) {
        emit(state.copyWith(
          isLoading: false,
          isEditMode: true,
          task: task,
          title: task.title,
          description: task.description,
          priority: task.priority,
          dueDate: task.dueDate,
          categoryId: task.categoryId,
          failure: null,
        ));
      },
    );
  }

  Future<void> _onUpdateTitle(
    _UpdateTitle event,
    Emitter<TaskEditState> emit,
  ) async {
    emit(state.copyWith(title: event.title));
  }

  Future<void> _onUpdateDescription(
    _UpdateDescription event,
    Emitter<TaskEditState> emit,
  ) async {
    emit(state.copyWith(description: event.description));
  }

  Future<void> _onUpdatePriority(
    _UpdatePriority event,
    Emitter<TaskEditState> emit,
  ) async {
    emit(state.copyWith(priority: event.priority));
  }

  Future<void> _onUpdateDueDate(
    _UpdateDueDate event,
    Emitter<TaskEditState> emit,
  ) async {
    emit(state.copyWith(dueDate: event.dueDate));
  }

  Future<void> _onUpdateCategory(
    _UpdateCategory event,
    Emitter<TaskEditState> emit,
  ) async {
    emit(state.copyWith(categoryId: event.categoryId));
  }

  Future<void> _onSaveTask(
    _SaveTask event,
    Emitter<TaskEditState> emit,
  ) async {
    // Validate title
    final title = state.title.trim();
    if (title.isEmpty) {
      emitUiEffect(const TaskEditUiEffect.showError('Title cannot be empty'));
      return;
    }

    emit(state.copyWith(isSaving: true));

    final now = DateTime.now();
    final Task task;

    if (state.isEditMode && state.task != null) {
      // Update existing task
      task = state.task!.copyWith(
        title: title,
        description: state.description,
        priority: state.priority,
        dueDate: state.dueDate,
        categoryId: state.categoryId,
        updatedAt: now,
      );

      final result = await _updateTaskUseCase(task);

      result.fold(
        (failure) {
          emit(state.copyWith(
            isSaving: false,
            failure: failure,
          ));
          emitUiEffect(TaskEditUiEffect.showError(failure.message));
        },
        (updatedTask) {
          emit(state.copyWith(isSaving: false));
          emitUiEffect(const TaskEditUiEffect.showSuccess('Task updated'));
          emitUiEffect(const TaskEditUiEffect.navigateBack());
        },
      );
    } else {
      // Create new task
      task = Task(
        id: _uuid.v4(),
        title: title,
        description: state.description,
        isCompleted: false,
        priority: state.priority,
        dueDate: state.dueDate,
        categoryId: state.categoryId,
        createdAt: now,
        updatedAt: now,
      );

      final result = await _createTaskUseCase(task);

      result.fold(
        (failure) {
          emit(state.copyWith(
            isSaving: false,
            failure: failure,
          ));
          emitUiEffect(TaskEditUiEffect.showError(failure.message));
        },
        (createdTask) {
          emit(state.copyWith(isSaving: false));
          emitUiEffect(const TaskEditUiEffect.showSuccess('Task created'));
          emitUiEffect(const TaskEditUiEffect.navigateBack());
        },
      );
    }
  }
}
