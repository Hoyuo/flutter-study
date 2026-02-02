import 'package:core/core.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/task.dart';
import '../../domain/usecases/get_tasks_params.dart';
import '../../domain/usecases/get_tasks_usecase.dart';
import '../../domain/usecases/delete_task_usecase.dart';
import '../../domain/usecases/toggle_task_completion_usecase.dart';
import '../../domain/usecases/search_tasks_usecase.dart';

part 'task_bloc.freezed.dart';
part 'task_event.dart';
part 'task_state.dart';
part 'task_ui_effect.dart';

/// BLoC for managing task list with filtering and searching
class TaskBloc extends Bloc<TaskEvent, TaskState>
    with BlocUiEffectMixin<TaskUiEffect, TaskState> {
  final GetTasksUseCase _getTasksUseCase;
  final DeleteTaskUseCase _deleteTaskUseCase;
  final ToggleTaskCompletionUseCase _toggleTaskCompletionUseCase;
  final SearchTasksUseCase _searchTasksUseCase;

  TaskBloc({
    required GetTasksUseCase getTasksUseCase,
    required DeleteTaskUseCase deleteTaskUseCase,
    required ToggleTaskCompletionUseCase toggleTaskCompletionUseCase,
    required SearchTasksUseCase searchTasksUseCase,
  })  : _getTasksUseCase = getTasksUseCase,
        _deleteTaskUseCase = deleteTaskUseCase,
        _toggleTaskCompletionUseCase = toggleTaskCompletionUseCase,
        _searchTasksUseCase = searchTasksUseCase,
        super(const TaskState()) {
    on<TaskEvent>(_onEvent);
  }

  Future<void> _onEvent(TaskEvent event, Emitter<TaskState> emit) async {
    await event.map(
      loadTasks: (e) => _onLoadTasks(e, emit),
      loadMoreTasks: (e) => _onLoadMoreTasks(e, emit),
      searchTasks: (e) => _onSearchTasks(e, emit),
      toggleCompletion: (e) => _onToggleCompletion(e, emit),
      deleteTask: (e) => _onDeleteTask(e, emit),
      applyFilter: (e) => _onApplyFilter(e, emit),
      clearFilter: (e) => _onClearFilter(e, emit),
    );
  }

  Future<void> _onLoadTasks(
    _LoadTasks event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final params = state.currentParams.copyWith(offset: 0);
    final result = await _getTasksUseCase(params);

    result.fold(
      (failure) {
        emit(state.copyWith(
          isLoading: false,
          failure: failure,
        ));
        emitUiEffect(TaskUiEffect.showError(failure.message));
      },
      (tasks) {
        emit(state.copyWith(
          isLoading: false,
          tasks: tasks,
          hasReachedEnd: tasks.length < params.limit,
          currentParams: params,
          failure: null,
        ));
      },
    );
  }

  Future<void> _onLoadMoreTasks(
    _LoadMoreTasks event,
    Emitter<TaskState> emit,
  ) async {
    if (state.hasReachedEnd || state.isLoading) return;

    emit(state.copyWith(isLoadingMore: true));

    final params = state.currentParams.copyWith(
      offset: state.tasks.length,
    );

    final result = await _getTasksUseCase(params);

    result.fold(
      (failure) {
        emit(state.copyWith(isLoadingMore: false));
        emitUiEffect(TaskUiEffect.showError(failure.message));
      },
      (newTasks) {
        emit(state.copyWith(
          isLoadingMore: false,
          tasks: [...state.tasks, ...newTasks],
          hasReachedEnd: newTasks.length < params.limit,
          currentParams: params.copyWith(offset: state.tasks.length + newTasks.length),
        ));
      },
    );
  }

  Future<void> _onSearchTasks(
    _SearchTasks event,
    Emitter<TaskState> emit,
  ) async {
    final query = event.query.trim();

    if (query.isEmpty) {
      // Clear search and reload tasks
      emit(state.copyWith(searchQuery: ''));
      add(const TaskEvent.loadTasks());
      return;
    }

    emit(state.copyWith(
      isLoading: true,
      searchQuery: query,
    ));

    final result = await _searchTasksUseCase(query);

    result.fold(
      (failure) {
        emit(state.copyWith(
          isLoading: false,
          failure: failure,
        ));
        emitUiEffect(TaskUiEffect.showError(failure.message));
      },
      (tasks) {
        emit(state.copyWith(
          isLoading: false,
          tasks: tasks,
          hasReachedEnd: true, // Search results are not paginated
          failure: null,
        ));
      },
    );
  }

  Future<void> _onToggleCompletion(
    _ToggleCompletion event,
    Emitter<TaskState> emit,
  ) async {
    final result = await _toggleTaskCompletionUseCase(event.taskId);

    result.fold(
      (failure) {
        emitUiEffect(TaskUiEffect.showError(failure.message));
      },
      (updatedTask) {
        // Update task in list
        final updatedTasks = state.tasks.map((task) {
          return task.id == updatedTask.id ? updatedTask : task;
        }).toList();

        emit(state.copyWith(tasks: updatedTasks));

        emitUiEffect(
          updatedTask.isCompleted
              ? const TaskUiEffect.showSuccess('Task completed')
              : const TaskUiEffect.showSuccess('Task reopened'),
        );
      },
    );
  }

  Future<void> _onDeleteTask(
    _DeleteTask event,
    Emitter<TaskState> emit,
  ) async {
    // Show confirmation dialog
    emitUiEffect(TaskUiEffect.confirmDelete(
      taskId: event.taskId,
      taskTitle: event.taskTitle,
      // coverage:ignore-start
      onConfirm: () async {
        final result = await _deleteTaskUseCase(event.taskId);

        result.fold(
          (failure) {
            emitUiEffect(TaskUiEffect.showError(failure.message));
          },
          (_) {
            // Remove task from list
            final updatedTasks = state.tasks
                .where((task) => task.id != event.taskId)
                .toList();

            emit(state.copyWith(tasks: updatedTasks));
            emitUiEffect(const TaskUiEffect.showSuccess('Task deleted'));
          },
        );
      },
      // coverage:ignore-end
    ));
  }

  Future<void> _onApplyFilter(
    _ApplyFilter event,
    Emitter<TaskState> emit,
  ) async {
    final params = state.currentParams.copyWith(
      isCompleted: event.isCompleted,
      priority: event.priority,
      categoryId: event.categoryId,
      sortBy: event.sortBy,
      ascending: event.ascending,
      todayOnly: event.todayOnly,
      offset: 0,
    );

    emit(state.copyWith(
      currentParams: params,
      searchQuery: '', // Clear search when applying filter
    ));

    add(const TaskEvent.loadTasks());
  }

  Future<void> _onClearFilter(
    _ClearFilter event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(
      currentParams: const GetTasksParams.defaults(),
      searchQuery: '',
    ));

    add(const TaskEvent.loadTasks());
  }
}
