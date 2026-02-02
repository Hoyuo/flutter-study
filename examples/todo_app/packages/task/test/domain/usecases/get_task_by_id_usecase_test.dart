import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:core/core.dart';
import 'package:task/domain/entities/task.dart';
import 'package:task/domain/repositories/task_repository.dart';
import 'package:task/domain/usecases/get_task_by_id_usecase.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;
  late GetTaskByIdUseCase useCase;

  setUp(() {
    mockRepository = MockTaskRepository();
    useCase = GetTaskByIdUseCase(mockRepository);
  });

  final now = DateTime(2024, 1, 1);
  final task = Task(
    id: '1',
    title: 'Test Task',
    createdAt: now,
    updatedAt: now,
  );

  group('GetTaskByIdUseCase', () {
    test('should get task from repository when task exists', () async {
      // arrange
      const taskId = '1';
      when(() => mockRepository.getTask(taskId))
          .thenAnswer((_) async => Right(task));

      // act
      final result = await useCase(taskId);

      // assert
      expect(result, Right(task));
      verify(() => mockRepository.getTask(taskId)).called(1);
    });

    test('should return failure when task does not exist', () async {
      // arrange
      const taskId = 'non-existent';
      final failure = Failure.notFound(message: 'Task not found');
      when(() => mockRepository.getTask(taskId))
          .thenAnswer((_) async => Left(failure));

      // act
      final result = await useCase(taskId);

      // assert
      expect(result, Left(failure));
      verify(() => mockRepository.getTask(taskId)).called(1);
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
      verifyNever(() => mockRepository.getTask(taskId));
    });

    test('should return failure when repository throws error', () async {
      // arrange
      const taskId = '1';
      final failure = Failure.unknown(message: 'Database error');
      when(() => mockRepository.getTask(taskId))
          .thenAnswer((_) async => Left(failure));

      // act
      final result = await useCase(taskId);

      // assert
      expect(result, Left(failure));
    });

    test('should get task with all fields populated', () async {
      // arrange
      const taskId = '1';
      final dueDate = DateTime(2024, 1, 15);
      final fullTask = Task(
        id: '1',
        title: 'Full Task',
        description: 'Full Description',
        isCompleted: true,
        priority: Priority.high,
        dueDate: dueDate,
        categoryId: 'cat-1',
        createdAt: now,
        updatedAt: now,
      );
      when(() => mockRepository.getTask(taskId))
          .thenAnswer((_) async => Right(fullTask));

      // act
      final result = await useCase(taskId);

      // assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not be left'),
        (task) {
          expect(task.id, '1');
          expect(task.title, 'Full Task');
          expect(task.description, 'Full Description');
          expect(task.isCompleted, true);
          expect(task.priority, Priority.high);
          expect(task.dueDate, dueDate);
          expect(task.categoryId, 'cat-1');
        },
      );
    });
  });
}
