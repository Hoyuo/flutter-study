import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:core/core.dart';
import 'package:task/domain/entities/task.dart';
import 'package:task/domain/repositories/task_repository.dart';
import 'package:task/domain/usecases/get_tasks_params.dart';
import 'package:task/domain/usecases/get_tasks_usecase.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;
  late GetTasksUseCase useCase;

  setUp(() {
    mockRepository = MockTaskRepository();
    useCase = GetTasksUseCase(mockRepository);
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

  group('GetTasksUseCase', () {
    test('should get tasks from repository with default params', () async {
      // arrange
      const params = GetTasksParams.defaults();
      final tasks = [task1, task2];
      when(() => mockRepository.getTasks(params))
          .thenAnswer((_) async => Right(tasks));

      // act
      final result = await useCase(params);

      // assert
      expect(result, Right(tasks));
      verify(() => mockRepository.getTasks(params)).called(1);
    });

    test('should get tasks with custom params', () async {
      // arrange
      const params = GetTasksParams(
        limit: 10,
        offset: 5,
        isCompleted: true,
        priority: Priority.high,
        categoryId: 'cat-1',
        sortBy: TaskSortBy.priority,
        ascending: true,
      );
      final tasks = [task1];
      when(() => mockRepository.getTasks(params))
          .thenAnswer((_) async => Right(tasks));

      // act
      final result = await useCase(params);

      // assert
      expect(result, Right(tasks));
      verify(() => mockRepository.getTasks(params)).called(1);
    });

    test('should return empty list when no tasks match', () async {
      // arrange
      const params = GetTasksParams.defaults();
      when(() => mockRepository.getTasks(params))
          .thenAnswer((_) async => const Right([]));

      // act
      final result = await useCase(params);

      // assert
      expect(result, const Right<Failure, List<Task>>([]));
    });

    test('should return failure when repository fails', () async {
      // arrange
      const params = GetTasksParams.defaults();
      final failure = Failure.unknown(message: 'Database error');
      when(() => mockRepository.getTasks(params))
          .thenAnswer((_) async => Left(failure));

      // act
      final result = await useCase(params);

      // assert
      expect(result, Left(failure));
    });

    test('should handle different sort options', () async {
      // arrange
      for (final sortBy in TaskSortBy.values) {
        final params = GetTasksParams(sortBy: sortBy);
        when(() => mockRepository.getTasks(params))
            .thenAnswer((_) async => Right([task1, task2]));

        // act
        final result = await useCase(params);

        // assert
        expect(result.isRight(), true);
        verify(() => mockRepository.getTasks(params)).called(1);
      }
    });

    test('should handle pagination params', () async {
      // arrange
      const params = GetTasksParams(limit: 5, offset: 10);
      final tasks = [task1];
      when(() => mockRepository.getTasks(params))
          .thenAnswer((_) async => Right(tasks));

      // act
      final result = await useCase(params);

      // assert
      expect(result, Right(tasks));
    });

    test('should filter by completion status', () async {
      // arrange
      const params = GetTasksParams(isCompleted: true);
      final completedTask = task1.copyWith(isCompleted: true);
      when(() => mockRepository.getTasks(params))
          .thenAnswer((_) async => Right([completedTask]));

      // act
      final result = await useCase(params);

      // assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not be left'),
        (tasks) {
          expect(tasks.length, 1);
          expect(tasks.first.isCompleted, true);
        },
      );
    });

    test('should filter by priority', () async {
      // arrange
      const params = GetTasksParams(priority: Priority.high);
      final highPriorityTask = task1.copyWith(priority: Priority.high);
      when(() => mockRepository.getTasks(params))
          .thenAnswer((_) async => Right([highPriorityTask]));

      // act
      final result = await useCase(params);

      // assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not be left'),
        (tasks) {
          expect(tasks.length, 1);
          expect(tasks.first.priority, Priority.high);
        },
      );
    });

    test('should filter by category', () async {
      // arrange
      const params = GetTasksParams(categoryId: 'cat-1');
      final categorizedTask = task1.copyWith(categoryId: 'cat-1');
      when(() => mockRepository.getTasks(params))
          .thenAnswer((_) async => Right([categorizedTask]));

      // act
      final result = await useCase(params);

      // assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not be left'),
        (tasks) {
          expect(tasks.length, 1);
          expect(tasks.first.categoryId, 'cat-1');
        },
      );
    });

    test('should filter by todayOnly', () async {
      // arrange
      const params = GetTasksParams(todayOnly: true);
      final todayTask = task1.copyWith(dueDate: DateTime.now());
      when(() => mockRepository.getTasks(params))
          .thenAnswer((_) async => Right([todayTask]));

      // act
      final result = await useCase(params);

      // assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not be left'),
        (tasks) {
          expect(tasks.length, 1);
          expect(tasks.first.dueDate, isNotNull);
        },
      );
    });
  });
}
