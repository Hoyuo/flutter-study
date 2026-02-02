import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:core/core.dart';
import 'package:task/domain/entities/task.dart';
import 'package:task/domain/repositories/task_repository.dart';
import 'package:task/domain/usecases/toggle_task_completion_usecase.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;
  late ToggleTaskCompletionUseCase useCase;

  setUp(() {
    mockRepository = MockTaskRepository();
    useCase = ToggleTaskCompletionUseCase(mockRepository);
  });

  final now = DateTime(2024, 1, 1);

  group('ToggleTaskCompletionUseCase', () {
    test('should toggle task completion from false to true', () async {
      // arrange
      const taskId = '1';
      final completedTask = Task(
        id: '1',
        title: 'Task',
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
      );
      when(() => mockRepository.toggleTaskCompletion(taskId))
          .thenAnswer((_) async => Right(completedTask));

      // act
      final result = await useCase(taskId);

      // assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not be left'),
        (task) {
          expect(task.isCompleted, true);
        },
      );
      verify(() => mockRepository.toggleTaskCompletion(taskId)).called(1);
    });

    test('should toggle task completion from true to false', () async {
      // arrange
      const taskId = '1';
      final uncompletedTask = Task(
        id: '1',
        title: 'Task',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );
      when(() => mockRepository.toggleTaskCompletion(taskId))
          .thenAnswer((_) async => Right(uncompletedTask));

      // act
      final result = await useCase(taskId);

      // assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not be left'),
        (task) {
          expect(task.isCompleted, false);
        },
      );
      verify(() => mockRepository.toggleTaskCompletion(taskId)).called(1);
    });

    test('should return validation failure when id is empty', () async {
      // arrange
      const taskId = '';

      // act
      final result = await useCase(taskId);

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<Failure>());
          expect(failure.message, 'Task ID cannot be empty');
        },
        (r) => fail('Should not be right'),
      );
      verifyNever(() => mockRepository.toggleTaskCompletion(taskId));
    });

    test('should return failure when task does not exist', () async {
      // arrange
      const taskId = 'non-existent';
      final failure = Failure.notFound(message: 'Task not found');
      when(() => mockRepository.toggleTaskCompletion(taskId))
          .thenAnswer((_) async => Left(failure));

      // act
      final result = await useCase(taskId);

      // assert
      expect(result, Left(failure));
      verify(() => mockRepository.toggleTaskCompletion(taskId)).called(1);
    });

    test('should return failure when repository fails', () async {
      // arrange
      const taskId = '1';
      final failure = Failure.unknown(message: 'Database error');
      when(() => mockRepository.toggleTaskCompletion(taskId))
          .thenAnswer((_) async => Left(failure));

      // act
      final result = await useCase(taskId);

      // assert
      expect(result, Left(failure));
    });

    test('should preserve other task properties when toggling', () async {
      // arrange
      const taskId = '1';
      final dueDate = DateTime(2024, 1, 15);
      final toggledTask = Task(
        id: '1',
        title: 'Important Task',
        description: 'Task Description',
        isCompleted: true,
        priority: Priority.high,
        dueDate: dueDate,
        categoryId: 'cat-1',
        createdAt: now,
        updatedAt: now,
      );
      when(() => mockRepository.toggleTaskCompletion(taskId))
          .thenAnswer((_) async => Right(toggledTask));

      // act
      final result = await useCase(taskId);

      // assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not be left'),
        (task) {
          expect(task.id, '1');
          expect(task.title, 'Important Task');
          expect(task.description, 'Task Description');
          expect(task.priority, Priority.high);
          expect(task.dueDate, dueDate);
          expect(task.categoryId, 'cat-1');
        },
      );
    });

    test('should handle multiple toggle operations on same task', () async {
      // arrange
      const taskId = '1';
      final completedTask = Task(
        id: '1',
        title: 'Task',
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
      );
      final uncompletedTask = completedTask.copyWith(isCompleted: false);

      when(() => mockRepository.toggleTaskCompletion(taskId))
          .thenAnswer((_) async => Right(completedTask));

      // act - first toggle
      final result1 = await useCase(taskId);

      when(() => mockRepository.toggleTaskCompletion(taskId))
          .thenAnswer((_) async => Right(uncompletedTask));

      // act - second toggle
      final result2 = await useCase(taskId);

      // assert
      expect(result1.isRight(), true);
      result1.fold(
        (l) => fail('Should not be left'),
        (task) => expect(task.isCompleted, true),
      );

      expect(result2.isRight(), true);
      result2.fold(
        (l) => fail('Should not be left'),
        (task) => expect(task.isCompleted, false),
      );

      verify(() => mockRepository.toggleTaskCompletion(taskId)).called(2);
    });

    test('should handle UUID-format task ids', () async {
      // arrange
      const taskId = '550e8400-e29b-41d4-a716-446655440000';
      final task = Task(
        id: taskId,
        title: 'Task',
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
      );
      when(() => mockRepository.toggleTaskCompletion(taskId))
          .thenAnswer((_) async => Right(task));

      // act
      final result = await useCase(taskId);

      // assert
      expect(result.isRight(), true);
      verify(() => mockRepository.toggleTaskCompletion(taskId)).called(1);
    });
  });
}
