import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:core/core.dart';
import 'package:uuid/uuid.dart';
import 'package:task/domain/entities/task.dart';
import 'package:task/domain/usecases/get_task_by_id_usecase.dart';
import 'package:task/domain/usecases/create_task_usecase.dart';
import 'package:task/domain/usecases/update_task_usecase.dart';
import 'package:task/presentation/bloc/task_edit_bloc.dart';

class MockGetTaskByIdUseCase extends Mock implements GetTaskByIdUseCase {}
class MockCreateTaskUseCase extends Mock implements CreateTaskUseCase {}
class MockUpdateTaskUseCase extends Mock implements UpdateTaskUseCase {}
class MockUuid extends Mock implements Uuid {}

void main() {
  late MockGetTaskByIdUseCase mockGetTaskByIdUseCase;
  late MockCreateTaskUseCase mockCreateTaskUseCase;
  late MockUpdateTaskUseCase mockUpdateTaskUseCase;
  late MockUuid mockUuid;
  late TaskEditBloc bloc;

  setUp(() {
    mockGetTaskByIdUseCase = MockGetTaskByIdUseCase();
    mockCreateTaskUseCase = MockCreateTaskUseCase();
    mockUpdateTaskUseCase = MockUpdateTaskUseCase();
    mockUuid = MockUuid();

    bloc = TaskEditBloc(
      getTaskByIdUseCase: mockGetTaskByIdUseCase,
      createTaskUseCase: mockCreateTaskUseCase,
      updateTaskUseCase: mockUpdateTaskUseCase,
      uuid: mockUuid,
    );
  });

  setUpAll(() {
    registerFallbackValue(Task(
      id: '1',
      title: 'Test',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  });

  tearDown(() {
    bloc.close();
  });

  final now = DateTime(2024, 1, 1);
  final dueDate = DateTime(2024, 1, 15);
  final task = Task(
    id: '1',
    title: 'Test Task',
    description: 'Test Description',
    isCompleted: false,
    priority: Priority.high,
    dueDate: dueDate,
    categoryId: 'cat-1',
    createdAt: now,
    updatedAt: now,
  );

  group('TaskEditBloc', () {
    test('initial state is correct', () {
      expect(bloc.state, const TaskEditState());
    });

    group('LoadTask', () {
      blocTest<TaskEditBloc, TaskEditState>(
        'sets create mode when taskId is null',
        build: () => bloc,
        act: (bloc) => bloc.add(const TaskEditEvent.loadTask(null)),
        expect: () => [
          const TaskEditState(
            isEditMode: false,
            isLoading: false,
          ),
        ],
      );

      blocTest<TaskEditBloc, TaskEditState>(
        'loads task in edit mode when taskId is provided',
        build: () {
          when(() => mockGetTaskByIdUseCase('1'))
              .thenAnswer((_) async => Right(task));
          return bloc;
        },
        act: (bloc) => bloc.add(const TaskEditEvent.loadTask('1')),
        expect: () => [
          const TaskEditState(isLoading: true),
          TaskEditState(
            isLoading: false,
            isEditMode: true,
            task: task,
            title: task.title,
            description: task.description,
            priority: task.priority,
            dueDate: task.dueDate,
            categoryId: task.categoryId,
          ),
        ],
        verify: (_) {
          verify(() => mockGetTaskByIdUseCase('1')).called(1);
        },
      );

      blocTest<TaskEditBloc, TaskEditState>(
        'emits error state when task not found',
        build: () {
          final failure = Failure.notFound(message: 'Task not found');
          when(() => mockGetTaskByIdUseCase('1'))
              .thenAnswer((_) async => Left(failure));
          return bloc;
        },
        act: (bloc) => bloc.add(const TaskEditEvent.loadTask('1')),
        expect: () => [
          const TaskEditState(isLoading: true),
          TaskEditState(
            isLoading: false,
            failure: Failure.notFound(message: 'Task not found'),
          ),
        ],
      );
    });

    group('UpdateTitle', () {
      blocTest<TaskEditBloc, TaskEditState>(
        'updates title in state',
        build: () => bloc,
        act: (bloc) => bloc.add(const TaskEditEvent.updateTitle('New Title')),
        expect: () => [
          const TaskEditState(title: 'New Title'),
        ],
      );
    });

    group('UpdateDescription', () {
      blocTest<TaskEditBloc, TaskEditState>(
        'updates description in state',
        build: () => bloc,
        act: (bloc) => bloc.add(const TaskEditEvent.updateDescription('New Description')),
        expect: () => [
          const TaskEditState(description: 'New Description'),
        ],
      );
    });

    group('UpdatePriority', () {
      blocTest<TaskEditBloc, TaskEditState>(
        'updates priority in state',
        build: () => bloc,
        act: (bloc) => bloc.add(const TaskEditEvent.updatePriority(Priority.high)),
        expect: () => [
          const TaskEditState(priority: Priority.high),
        ],
      );
    });

    group('UpdateDueDate', () {
      blocTest<TaskEditBloc, TaskEditState>(
        'updates due date in state',
        build: () => bloc,
        act: (bloc) => bloc.add(TaskEditEvent.updateDueDate(dueDate)),
        expect: () => [
          TaskEditState(dueDate: dueDate),
        ],
      );

      blocTest<TaskEditBloc, TaskEditState>(
        'can clear due date',
        build: () => bloc,
        seed: () => TaskEditState(dueDate: dueDate),
        act: (bloc) => bloc.add(const TaskEditEvent.updateDueDate(null)),
        expect: () => [
          const TaskEditState(dueDate: null),
        ],
      );
    });

    group('UpdateCategory', () {
      blocTest<TaskEditBloc, TaskEditState>(
        'updates category in state',
        build: () => bloc,
        act: (bloc) => bloc.add(const TaskEditEvent.updateCategory('cat-1')),
        expect: () => [
          const TaskEditState(categoryId: 'cat-1'),
        ],
      );

      blocTest<TaskEditBloc, TaskEditState>(
        'can clear category',
        build: () => bloc,
        seed: () => const TaskEditState(categoryId: 'cat-1'),
        act: (bloc) => bloc.add(const TaskEditEvent.updateCategory(null)),
        expect: () => [
          const TaskEditState(categoryId: null),
        ],
      );
    });

    group('SaveTask - Create Mode', () {
      blocTest<TaskEditBloc, TaskEditState>(
        'creates new task with generated ID',
        build: () {
          when(() => mockUuid.v4()).thenReturn('new-id');
          when(() => mockCreateTaskUseCase(any())).thenAnswer(
            (_) async => Right(Task(
              id: 'new-id',
              title: 'New Task',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            )),
          );
          return bloc;
        },
        seed: () => const TaskEditState(
          title: 'New Task',
          isEditMode: false,
        ),
        act: (bloc) => bloc.add(const TaskEditEvent.saveTask()),
        expect: () => [
          const TaskEditState(
            title: 'New Task',
            isEditMode: false,
            isSaving: true,
          ),
          const TaskEditState(
            title: 'New Task',
            isEditMode: false,
            isSaving: false,
          ),
        ],
        verify: (_) {
          verify(() => mockUuid.v4()).called(1);
          verify(() => mockCreateTaskUseCase(any())).called(1);
        },
      );

      blocTest<TaskEditBloc, TaskEditState>(
        'does not save when title is empty',
        build: () => bloc,
        seed: () => const TaskEditState(
          title: '',
          isEditMode: false,
        ),
        act: (bloc) => bloc.add(const TaskEditEvent.saveTask()),
        expect: () => [],
        verify: (_) {
          verifyNever(() => mockCreateTaskUseCase(any()));
        },
      );

      blocTest<TaskEditBloc, TaskEditState>(
        'does not save when title is only whitespace',
        build: () => bloc,
        seed: () => const TaskEditState(
          title: '   ',
          isEditMode: false,
        ),
        act: (bloc) => bloc.add(const TaskEditEvent.saveTask()),
        expect: () => [],
        verify: (_) {
          verifyNever(() => mockCreateTaskUseCase(any()));
        },
      );

      blocTest<TaskEditBloc, TaskEditState>(
        'creates task with all fields',
        build: () {
          when(() => mockUuid.v4()).thenReturn('new-id');
          when(() => mockCreateTaskUseCase(any())).thenAnswer(
            (_) async => Right(Task(
              id: 'new-id',
              title: 'Full Task',
              description: 'Description',
              priority: Priority.high,
              dueDate: dueDate,
              categoryId: 'cat-1',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            )),
          );
          return bloc;
        },
        seed: () => TaskEditState(
          title: 'Full Task',
          description: 'Description',
          priority: Priority.high,
          dueDate: dueDate,
          categoryId: 'cat-1',
          isEditMode: false,
        ),
        act: (bloc) => bloc.add(const TaskEditEvent.saveTask()),
        expect: () => [
          TaskEditState(
            title: 'Full Task',
            description: 'Description',
            priority: Priority.high,
            dueDate: dueDate,
            categoryId: 'cat-1',
            isEditMode: false,
            isSaving: true,
          ),
          TaskEditState(
            title: 'Full Task',
            description: 'Description',
            priority: Priority.high,
            dueDate: dueDate,
            categoryId: 'cat-1',
            isEditMode: false,
            isSaving: false,
          ),
        ],
      );

      blocTest<TaskEditBloc, TaskEditState>(
        'emits error state on create failure',
        build: () {
          when(() => mockUuid.v4()).thenReturn('new-id');
          final failure = Failure.unknown(message: 'Create error');
          when(() => mockCreateTaskUseCase(any()))
              .thenAnswer((_) async => Left(failure));
          return bloc;
        },
        seed: () => const TaskEditState(
          title: 'New Task',
          isEditMode: false,
        ),
        act: (bloc) => bloc.add(const TaskEditEvent.saveTask()),
        expect: () => [
          const TaskEditState(
            title: 'New Task',
            isEditMode: false,
            isSaving: true,
          ),
          TaskEditState(
            title: 'New Task',
            isEditMode: false,
            isSaving: false,
            failure: Failure.unknown(message: 'Create error'),
          ),
        ],
      );
    });

    group('SaveTask - Edit Mode', () {
      blocTest<TaskEditBloc, TaskEditState>(
        'updates existing task',
        build: () {
          when(() => mockUpdateTaskUseCase(any())).thenAnswer(
            (_) async => Right(task.copyWith(title: 'Updated Task')),
          );
          return bloc;
        },
        seed: () => TaskEditState(
          task: task,
          title: 'Updated Task',
          description: task.description,
          priority: task.priority,
          dueDate: task.dueDate,
          categoryId: task.categoryId,
          isEditMode: true,
        ),
        act: (bloc) => bloc.add(const TaskEditEvent.saveTask()),
        expect: () => [
          TaskEditState(
            task: task,
            title: 'Updated Task',
            description: task.description,
            priority: task.priority,
            dueDate: task.dueDate,
            categoryId: task.categoryId,
            isEditMode: true,
            isSaving: true,
          ),
          TaskEditState(
            task: task,
            title: 'Updated Task',
            description: task.description,
            priority: task.priority,
            dueDate: task.dueDate,
            categoryId: task.categoryId,
            isEditMode: true,
            isSaving: false,
          ),
        ],
        verify: (_) {
          verify(() => mockUpdateTaskUseCase(any())).called(1);
        },
      );

      blocTest<TaskEditBloc, TaskEditState>(
        'does not update when title is empty',
        build: () => bloc,
        seed: () => TaskEditState(
          task: task,
          title: '',
          isEditMode: true,
        ),
        act: (bloc) => bloc.add(const TaskEditEvent.saveTask()),
        expect: () => [],
        verify: (_) {
          verifyNever(() => mockUpdateTaskUseCase(any()));
        },
      );

      blocTest<TaskEditBloc, TaskEditState>(
        'emits error state on update failure',
        build: () {
          final failure = Failure.notFound(message: 'Task not found');
          when(() => mockUpdateTaskUseCase(any()))
              .thenAnswer((_) async => Left(failure));
          return bloc;
        },
        seed: () => TaskEditState(
          task: task,
          title: 'Updated Task',
          isEditMode: true,
        ),
        act: (bloc) => bloc.add(const TaskEditEvent.saveTask()),
        expect: () => [
          TaskEditState(
            task: task,
            title: 'Updated Task',
            isEditMode: true,
            isSaving: true,
          ),
          TaskEditState(
            task: task,
            title: 'Updated Task',
            isEditMode: true,
            isSaving: false,
            failure: Failure.notFound(message: 'Task not found'),
          ),
        ],
      );

      blocTest<TaskEditBloc, TaskEditState>(
        'updates all task fields',
        build: () {
          final updatedTask = task.copyWith(
            title: 'New Title',
            description: 'New Description',
            priority: Priority.low,
            dueDate: null,
            categoryId: null,
          );
          when(() => mockUpdateTaskUseCase(any()))
              .thenAnswer((_) async => Right(updatedTask));
          return bloc;
        },
        seed: () => TaskEditState(
          task: task,
          title: 'New Title',
          description: 'New Description',
          priority: Priority.low,
          dueDate: null,
          categoryId: null,
          isEditMode: true,
        ),
        act: (bloc) => bloc.add(const TaskEditEvent.saveTask()),
        expect: () => [
          TaskEditState(
            task: task,
            title: 'New Title',
            description: 'New Description',
            priority: Priority.low,
            dueDate: null,
            categoryId: null,
            isEditMode: true,
            isSaving: true,
          ),
          TaskEditState(
            task: task,
            title: 'New Title',
            description: 'New Description',
            priority: Priority.low,
            dueDate: null,
            categoryId: null,
            isEditMode: true,
            isSaving: false,
          ),
        ],
      );
    });

    group('SaveTask - Validation', () {
      blocTest<TaskEditBloc, TaskEditState>(
        'trims whitespace from title before saving',
        build: () {
          when(() => mockUuid.v4()).thenReturn('new-id');
          when(() => mockCreateTaskUseCase(any())).thenAnswer(
            (_) async => Right(Task(
              id: 'new-id',
              title: 'Trimmed Title',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            )),
          );
          return bloc;
        },
        seed: () => const TaskEditState(
          title: '  Trimmed Title  ',
          isEditMode: false,
        ),
        act: (bloc) => bloc.add(const TaskEditEvent.saveTask()),
        verify: (_) {
          verify(() => mockCreateTaskUseCase(any())).called(1);
        },
      );
    });
  });
}
