import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:core/core.dart';
import 'package:task/domain/entities/task.dart';
import 'package:task/domain/repositories/task_repository.dart';
import 'package:task/domain/usecases/update_task_usecase.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;
  late UpdateTaskUseCase useCase;

  setUp(() {
    mockRepository = MockTaskRepository();
    useCase = UpdateTaskUseCase(mockRepository);
  });

  setUpAll(() {
    registerFallbackValue(Task(
      id: '1',
      title: 'Test',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  });

  final now = DateTime(2024, 1, 1);

  group('UpdateTaskUseCase', () {
    test('should update task in repository', () async {
      // arrange
      final task = Task(
        id: '1',
        title: 'Updated Task',
        createdAt: now,
        updatedAt: now,
      );
      when(() => mockRepository.updateTask(any()))
          .thenAnswer((_) async => Right(task));

      // act
      final result = await useCase(task);

      // assert
      expect(result, Right(task));
      verify(() => mockRepository.updateTask(task)).called(1);
    });

    test('should update all task fields', () async {
      // arrange
      final dueDate = DateTime(2024, 1, 15);
      final task = Task(
        id: '1',
        title: 'Updated Task',
        description: 'Updated Description',
        isCompleted: true,
        priority: Priority.low,
        dueDate: dueDate,
        categoryId: 'new-cat',
        createdAt: now,
        updatedAt: now,
      );
      when(() => mockRepository.updateTask(any()))
          .thenAnswer((_) async => Right(task));

      // act
      final result = await useCase(task);

      // assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not be left'),
        (updatedTask) {
          expect(updatedTask.title, 'Updated Task');
          expect(updatedTask.description, 'Updated Description');
          expect(updatedTask.isCompleted, true);
          expect(updatedTask.priority, Priority.low);
          expect(updatedTask.dueDate, dueDate);
          expect(updatedTask.categoryId, 'new-cat');
        },
      );
    });

    test('should return validation failure when id is empty', () async {
      // arrange
      final task = Task(
        id: '',
        title: 'Updated Task',
        createdAt: now,
        updatedAt: now,
      );

      // act
      final result = await useCase(task);

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<Failure>());
          expect(failure.message, 'Task ID cannot be empty');
        },
        (r) => fail('Should not be right'),
      );
      verifyNever(() => mockRepository.updateTask(any()));
    });

    test('should return validation failure when title is empty', () async {
      // arrange
      final task = Task(
        id: '1',
        title: '',
        createdAt: now,
        updatedAt: now,
      );

      // act
      final result = await useCase(task);

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<Failure>());
          expect(failure.message, 'Task title cannot be empty');
        },
        (r) => fail('Should not be right'),
      );
      verifyNever(() => mockRepository.updateTask(any()));
    });

    test('should return validation failure when title is only whitespace', () async {
      // arrange
      final task = Task(
        id: '1',
        title: '   ',
        createdAt: now,
        updatedAt: now,
      );

      // act
      final result = await useCase(task);

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<Failure>());
          expect(failure.message, 'Task title cannot be empty');
        },
        (r) => fail('Should not be right'),
      );
      verifyNever(() => mockRepository.updateTask(any()));
    });

    test('should return failure when task does not exist', () async {
      // arrange
      final task = Task(
        id: 'non-existent',
        title: 'Updated Task',
        createdAt: now,
        updatedAt: now,
      );
      final failure = Failure.notFound(message: 'Task not found');
      when(() => mockRepository.updateTask(any()))
          .thenAnswer((_) async => Left(failure));

      // act
      final result = await useCase(task);

      // assert
      expect(result, Left(failure));
    });

    test('should return failure when repository fails', () async {
      // arrange
      final task = Task(
        id: '1',
        title: 'Updated Task',
        createdAt: now,
        updatedAt: now,
      );
      final failure = Failure.unknown(message: 'Database error');
      when(() => mockRepository.updateTask(any()))
          .thenAnswer((_) async => Left(failure));

      // act
      final result = await useCase(task);

      // assert
      expect(result, Left(failure));
    });

    test('should trim title before validation', () async {
      // arrange
      final task = Task(
        id: '1',
        title: '  Valid Title  ',
        createdAt: now,
        updatedAt: now,
      );
      when(() => mockRepository.updateTask(any()))
          .thenAnswer((_) async => Right(task));

      // act
      final result = await useCase(task);

      // assert
      expect(result.isRight(), true);
      verify(() => mockRepository.updateTask(task)).called(1);
    });

    test('should update completion status', () async {
      // arrange
      final task = Task(
        id: '1',
        title: 'Task',
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
      );
      when(() => mockRepository.updateTask(any()))
          .thenAnswer((_) async => Right(task));

      // act
      final result = await useCase(task);

      // assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not be left'),
        (updatedTask) {
          expect(updatedTask.isCompleted, true);
        },
      );
    });

    test('should update priority', () async {
      // Test updating to each priority level
      for (final priority in Priority.values) {
        final task = Task(
          id: '1',
          title: 'Task',
          priority: priority,
          createdAt: now,
          updatedAt: now,
        );
        when(() => mockRepository.updateTask(any()))
            .thenAnswer((_) async => Right(task));

        final result = await useCase(task);

        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not be left'),
          (updatedTask) {
            expect(updatedTask.priority, priority);
          },
        );
      }
    });

    test('should clear optional fields', () async {
      // arrange
      final task = Task(
        id: '1',
        title: 'Task',
        description: '',
        dueDate: null,
        categoryId: null,
        createdAt: now,
        updatedAt: now,
      );
      when(() => mockRepository.updateTask(any()))
          .thenAnswer((_) async => Right(task));

      // act
      final result = await useCase(task);

      // assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not be left'),
        (updatedTask) {
          expect(updatedTask.description, '');
          expect(updatedTask.dueDate, isNull);
          expect(updatedTask.categoryId, isNull);
        },
      );
    });
  });
}
