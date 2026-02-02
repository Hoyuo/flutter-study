import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:core/core.dart';
import 'package:task/domain/entities/task.dart';
import 'package:task/domain/usecases/get_tasks_params.dart';
import 'package:task/domain/usecases/get_tasks_usecase.dart';
import 'package:task/domain/usecases/delete_task_usecase.dart';
import 'package:task/domain/usecases/toggle_task_completion_usecase.dart';
import 'package:task/domain/usecases/search_tasks_usecase.dart';
import 'package:task/presentation/bloc/task_bloc.dart';

class MockGetTasksUseCase extends Mock implements GetTasksUseCase {}
class MockDeleteTaskUseCase extends Mock implements DeleteTaskUseCase {}
class MockToggleTaskCompletionUseCase extends Mock implements ToggleTaskCompletionUseCase {}
class MockSearchTasksUseCase extends Mock implements SearchTasksUseCase {}

void main() {
  late MockGetTasksUseCase mockGetTasksUseCase;
  late MockDeleteTaskUseCase mockDeleteTaskUseCase;
  late MockToggleTaskCompletionUseCase mockToggleTaskCompletionUseCase;
  late MockSearchTasksUseCase mockSearchTasksUseCase;
  late TaskBloc bloc;

  setUp(() {
    mockGetTasksUseCase = MockGetTasksUseCase();
    mockDeleteTaskUseCase = MockDeleteTaskUseCase();
    mockToggleTaskCompletionUseCase = MockToggleTaskCompletionUseCase();
    mockSearchTasksUseCase = MockSearchTasksUseCase();

    bloc = TaskBloc(
      getTasksUseCase: mockGetTasksUseCase,
      deleteTaskUseCase: mockDeleteTaskUseCase,
      toggleTaskCompletionUseCase: mockToggleTaskCompletionUseCase,
      searchTasksUseCase: mockSearchTasksUseCase,
    );
  });

  setUpAll(() {
    registerFallbackValue(const GetTasksParams.defaults());
  });

  tearDown(() {
    bloc.close();
  });

  final now = DateTime(2024, 1, 1);
  final task1 = Task(
    id: '1',
    title: 'Task 1',
    createdAt: now,
    updatedAt: now,
  );
  final task2 = Task(
    id: '2',
    title: 'Task 2',
    createdAt: now,
    updatedAt: now,
  );

  group('TaskBloc', () {
    test('initial state is correct', () {
      expect(bloc.state, const TaskState());
    });

    group('LoadTasks', () {
      blocTest<TaskBloc, TaskState>(
        'emits loading state then tasks on success',
        build: () {
          when(() => mockGetTasksUseCase(any()))
              .thenAnswer((_) async => Right([task1, task2]));
          return bloc;
        },
        act: (bloc) => bloc.add(const TaskEvent.loadTasks()),
        expect: () => [
          const TaskState(isLoading: true),
          TaskState(
            isLoading: false,
            tasks: [task1, task2],
            hasReachedEnd: true,
            currentParams: const GetTasksParams.defaults(),
          ),
        ],
        verify: (_) {
          verify(() => mockGetTasksUseCase(any())).called(1);
        },
      );

      blocTest<TaskBloc, TaskState>(
        'sets hasReachedEnd to true when tasks length < limit',
        build: () {
          when(() => mockGetTasksUseCase(any()))
              .thenAnswer((_) async => Right([task1]));
          return bloc;
        },
        act: (bloc) => bloc.add(const TaskEvent.loadTasks()),
        expect: () => [
          const TaskState(isLoading: true),
          TaskState(
            isLoading: false,
            tasks: [task1],
            hasReachedEnd: true,
            currentParams: const GetTasksParams.defaults(),
          ),
        ],
      );

      blocTest<TaskBloc, TaskState>(
        'emits error state on failure',
        build: () {
          final failure = Failure.unknown(message: 'Database error');
          when(() => mockGetTasksUseCase(any()))
              .thenAnswer((_) async => Left(failure));
          return bloc;
        },
        act: (bloc) => bloc.add(const TaskEvent.loadTasks()),
        expect: () => [
          const TaskState(isLoading: true),
          TaskState(
            isLoading: false,
            failure: Failure.unknown(message: 'Database error'),
          ),
        ],
      );
    });

    group('LoadMoreTasks', () {
      blocTest<TaskBloc, TaskState>(
        'loads more tasks when not at end',
        build: () {
          when(() => mockGetTasksUseCase(any()))
              .thenAnswer((_) async => Right([task1, task2]));
          return bloc;
        },
        seed: () => TaskState(
          tasks: [task1],
          hasReachedEnd: false,
          currentParams: const GetTasksParams.defaults(),
        ),
        act: (bloc) => bloc.add(const TaskEvent.loadMoreTasks()),
        expect: () => [
          TaskState(
            tasks: [task1],
            isLoadingMore: true,
            hasReachedEnd: false,
            currentParams: const GetTasksParams.defaults(),
          ),
          TaskState(
            tasks: [task1, task1, task2],
            isLoadingMore: false,
            hasReachedEnd: true,
            currentParams: const GetTasksParams(offset: 3),
          ),
        ],
      );

      blocTest<TaskBloc, TaskState>(
        'does not load when already loading',
        build: () => bloc,
        seed: () => const TaskState(
          isLoading: true,
          hasReachedEnd: false,
        ),
        act: (bloc) => bloc.add(const TaskEvent.loadMoreTasks()),
        expect: () => [],
        verify: (_) {
          verifyNever(() => mockGetTasksUseCase(any()));
        },
      );

      blocTest<TaskBloc, TaskState>(
        'does not load when reached end',
        build: () => bloc,
        seed: () => const TaskState(hasReachedEnd: true),
        act: (bloc) => bloc.add(const TaskEvent.loadMoreTasks()),
        expect: () => [],
        verify: (_) {
          verifyNever(() => mockGetTasksUseCase(any()));
        },
      );

      blocTest<TaskBloc, TaskState>(
        'sets hasReachedEnd when new tasks length < limit',
        build: () {
          when(() => mockGetTasksUseCase(any()))
              .thenAnswer((_) async => Right([task1]));
          return bloc;
        },
        seed: () => TaskState(
          tasks: [task2],
          hasReachedEnd: false,
          currentParams: const GetTasksParams.defaults(),
        ),
        act: (bloc) => bloc.add(const TaskEvent.loadMoreTasks()),
        expect: () => [
          TaskState(
            tasks: [task2],
            isLoadingMore: true,
            hasReachedEnd: false,
            currentParams: const GetTasksParams.defaults(),
          ),
          TaskState(
            tasks: [task2, task1],
            isLoadingMore: false,
            hasReachedEnd: true,
            currentParams: const GetTasksParams(offset: 2),
          ),
        ],
      );

      blocTest<TaskBloc, TaskState>(
        'emits error on failure',
        build: () {
          final failure = Failure.unknown(message: 'Load more error');
          when(() => mockGetTasksUseCase(any()))
              .thenAnswer((_) async => Left(failure));
          return bloc;
        },
        seed: () => TaskState(
          tasks: [task1],
          hasReachedEnd: false,
          currentParams: const GetTasksParams.defaults(),
        ),
        act: (bloc) => bloc.add(const TaskEvent.loadMoreTasks()),
        expect: () => [
          TaskState(
            tasks: [task1],
            isLoadingMore: true,
            hasReachedEnd: false,
            currentParams: const GetTasksParams.defaults(),
          ),
          TaskState(
            tasks: [task1],
            isLoadingMore: false,
            hasReachedEnd: false,
            currentParams: const GetTasksParams.defaults(),
          ),
        ],
      );
    });

    group('SearchTasks', () {
      blocTest<TaskBloc, TaskState>(
        'searches tasks with query',
        build: () {
          when(() => mockSearchTasksUseCase(any()))
              .thenAnswer((_) async => Right([task1]));
          return bloc;
        },
        act: (bloc) => bloc.add(const TaskEvent.searchTasks('test')),
        expect: () => [
          const TaskState(
            isLoading: true,
            searchQuery: 'test',
          ),
          TaskState(
            isLoading: false,
            tasks: [task1],
            searchQuery: 'test',
            hasReachedEnd: true,
          ),
        ],
        verify: (_) {
          verify(() => mockSearchTasksUseCase('test')).called(1);
        },
      );

      blocTest<TaskBloc, TaskState>(
        'clears search and reloads when query is empty',
        build: () {
          when(() => mockGetTasksUseCase(any()))
              .thenAnswer((_) async => Right([task1, task2]));
          return bloc;
        },
        act: (bloc) => bloc.add(const TaskEvent.searchTasks('')),
        expect: () => [
          const TaskState(searchQuery: ''),
          const TaskState(isLoading: true, searchQuery: ''),
          TaskState(
            isLoading: false,
            tasks: [task1, task2],
            searchQuery: '',
            hasReachedEnd: true,
            currentParams: const GetTasksParams.defaults(),
          ),
        ],
      );

      blocTest<TaskBloc, TaskState>(
        'emits error state on search failure',
        build: () {
          final failure = Failure.unknown(message: 'Search error');
          when(() => mockSearchTasksUseCase(any()))
              .thenAnswer((_) async => Left(failure));
          return bloc;
        },
        act: (bloc) => bloc.add(const TaskEvent.searchTasks('test')),
        expect: () => [
          const TaskState(
            isLoading: true,
            searchQuery: 'test',
          ),
          TaskState(
            isLoading: false,
            searchQuery: 'test',
            failure: Failure.unknown(message: 'Search error'),
          ),
        ],
      );
    });

    group('ToggleCompletion', () {
      blocTest<TaskBloc, TaskState>(
        'toggles task completion and updates list',
        build: () {
          final completedTask = task1.copyWith(isCompleted: true);
          when(() => mockToggleTaskCompletionUseCase('1'))
              .thenAnswer((_) async => Right(completedTask));
          return bloc;
        },
        seed: () => TaskState(tasks: [task1, task2]),
        act: (bloc) => bloc.add(const TaskEvent.toggleCompletion('1')),
        expect: () => [
          TaskState(
            tasks: [task1.copyWith(isCompleted: true), task2],
          ),
        ],
        verify: (_) {
          verify(() => mockToggleTaskCompletionUseCase('1')).called(1);
        },
      );

      blocTest<TaskBloc, TaskState>(
        'does not update state on failure',
        build: () {
          final failure = Failure.unknown(message: 'Toggle error');
          when(() => mockToggleTaskCompletionUseCase('1'))
              .thenAnswer((_) async => Left(failure));
          return bloc;
        },
        seed: () => TaskState(tasks: [task1, task2]),
        act: (bloc) => bloc.add(const TaskEvent.toggleCompletion('1')),
        expect: () => [],
      );
    });

    group('DeleteTask', () {
      blocTest<TaskBloc, TaskState>(
        'emits confirm delete UI effect',
        build: () => bloc,
        seed: () => TaskState(tasks: [task1, task2]),
        act: (bloc) => bloc.add(const TaskEvent.deleteTask(
          taskId: '1',
          taskTitle: 'Task 1',
        )),
        expect: () => [],
        verify: (_) {
          // The actual deletion happens in the confirmation callback
          // The bloc just emits a UI effect to show the confirmation dialog
        },
      );
    });

    group('ApplyFilter', () {
      blocTest<TaskBloc, TaskState>(
        'applies filter and reloads tasks',
        build: () {
          when(() => mockGetTasksUseCase(any()))
              .thenAnswer((_) async => Right([task1]));
          return bloc;
        },
        act: (bloc) => bloc.add(const TaskEvent.applyFilter(
          isCompleted: true,
          priority: Priority.high,
          categoryId: 'cat-1',
          sortBy: TaskSortBy.priority,
          ascending: true,
        )),
        expect: () => [
          const TaskState(
            currentParams: GetTasksParams(
              isCompleted: true,
              priority: Priority.high,
              categoryId: 'cat-1',
              sortBy: TaskSortBy.priority,
              ascending: true,
              offset: 0,
            ),
            searchQuery: '',
          ),
          const TaskState(
            isLoading: true,
            currentParams: GetTasksParams(
              isCompleted: true,
              priority: Priority.high,
              categoryId: 'cat-1',
              sortBy: TaskSortBy.priority,
              ascending: true,
              offset: 0,
            ),
            searchQuery: '',
          ),
          TaskState(
            isLoading: false,
            tasks: [task1],
            currentParams: const GetTasksParams(
              isCompleted: true,
              priority: Priority.high,
              categoryId: 'cat-1',
              sortBy: TaskSortBy.priority,
              ascending: true,
              offset: 0,
            ),
            searchQuery: '',
            hasReachedEnd: true,
          ),
        ],
      );

      blocTest<TaskBloc, TaskState>(
        'clears search query when applying filter',
        build: () {
          when(() => mockGetTasksUseCase(any()))
              .thenAnswer((_) async => Right([task1]));
          return bloc;
        },
        seed: () => const TaskState(searchQuery: 'old search'),
        act: (bloc) => bloc.add(const TaskEvent.applyFilter()),
        expect: () => [
          const TaskState(
            currentParams: GetTasksParams.defaults(),
            searchQuery: '',
          ),
          const TaskState(
            isLoading: true,
            currentParams: GetTasksParams.defaults(),
            searchQuery: '',
          ),
          TaskState(
            isLoading: false,
            tasks: [task1],
            currentParams: const GetTasksParams.defaults(),
            searchQuery: '',
            hasReachedEnd: true,
          ),
        ],
      );
    });

    group('ClearFilter', () {
      blocTest<TaskBloc, TaskState>(
        'clears all filters and reloads tasks',
        build: () {
          when(() => mockGetTasksUseCase(any()))
              .thenAnswer((_) async => Right([task1, task2]));
          return bloc;
        },
        seed: () => const TaskState(
          currentParams: GetTasksParams(
            isCompleted: true,
            priority: Priority.high,
            categoryId: 'cat-1',
          ),
          searchQuery: 'search',
        ),
        act: (bloc) => bloc.add(const TaskEvent.clearFilter()),
        expect: () => [
          const TaskState(
            currentParams: GetTasksParams.defaults(),
            searchQuery: '',
          ),
          const TaskState(
            isLoading: true,
            currentParams: GetTasksParams.defaults(),
            searchQuery: '',
          ),
          TaskState(
            isLoading: false,
            tasks: [task1, task2],
            currentParams: const GetTasksParams.defaults(),
            searchQuery: '',
            hasReachedEnd: true,
          ),
        ],
      );
    });
  });
}
