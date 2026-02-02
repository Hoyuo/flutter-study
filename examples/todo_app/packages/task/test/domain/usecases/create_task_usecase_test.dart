import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:core/core.dart';
import 'package:task/domain/entities/task.dart';
import 'package:task/domain/repositories/task_repository.dart';
import 'package:task/domain/usecases/create_task_usecase.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;
  late CreateTaskUseCase useCase;

  setUp(() {
    mockRepository = MockTaskRepository();
    useCase = CreateTaskUseCase(mockRepository);
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

  group('CreateTaskUseCase', () {
    test('should create task in repository', () async {
      // arrange
      final task = Task(
        id: '1',
        title: 'New Task',
        createdAt: now,
        updatedAt: now,
      );
      when(() => mockRepository.createTask(any()))
          .thenAnswer((_) async => Right(task));

      // act
      final result = await useCase(task);

      // assert
      expect(result, Right(task));
      verify(() => mockRepository.createTask(task)).called(1);
    });

    test('should create task with all fields', () async {
      // arrange
      final dueDate = DateTime(2024, 1, 15);
      final task = Task(
        id: '1',
        title: 'Full Task',
        description: 'Full Description',
        isCompleted: false,
        priority: Priority.high,
        dueDate: dueDate,
        categoryId: 'cat-1',
        createdAt: now,
        updatedAt: now,
      );
      when(() => mockRepository.createTask(any()))
          .thenAnswer((_) async => Right(task));

      // act
      final result = await useCase(task);

      // assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not be left'),
        (createdTask) {
          expect(createdTask.title, 'Full Task');
          expect(createdTask.description, 'Full Description');
          expect(createdTask.priority, Priority.high);
          expect(createdTask.dueDate, dueDate);
          expect(createdTask.categoryId, 'cat-1');
        },
      );
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
      verifyNever(() => mockRepository.createTask(any()));
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
      verifyNever(() => mockRepository.createTask(any()));
    });

    test('should return failure when repository fails', () async {
      // arrange
      final task = Task(
        id: '1',
        title: 'New Task',
        createdAt: now,
        updatedAt: now,
      );
      final failure = Failure.unknown(message: 'Database error');
      when(() => mockRepository.createTask(any()))
          .thenAnswer((_) async => Left(failure));

      // act
      final result = await useCase(task);

      // assert
      expect(result, Left(failure));
    });

    test('should return failure when task already exists', () async {
      // arrange
      final task = Task(
        id: '1',
        title: 'Existing Task',
        createdAt: now,
        updatedAt: now,
      );
      final failure = Failure.validation(message: 'Task with ID 1 already exists');
      when(() => mockRepository.createTask(any()))
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
      when(() => mockRepository.createTask(any()))
          .thenAnswer((_) async => Right(task));

      // act
      final result = await useCase(task);

      // assert
      expect(result.isRight(), true);
      verify(() => mockRepository.createTask(task)).called(1);
    });

    test('should create task with empty description', () async {
      // arrange
      final task = Task(
        id: '1',
        title: 'Task without description',
        description: '',
        createdAt: now,
        updatedAt: now,
      );
      when(() => mockRepository.createTask(any()))
          .thenAnswer((_) async => Right(task));

      // act
      final result = await useCase(task);

      // assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not be left'),
        (createdTask) {
          expect(createdTask.description, '');
        },
      );
    });

    test('should create task with different priority levels', () async {
      // Test each priority level
      for (final priority in Priority.values) {
        final task = Task(
          id: 'task-${priority.value}',
          title: 'Task with ${priority.name} priority',
          priority: priority,
          createdAt: now,
          updatedAt: now,
        );
        when(() => mockRepository.createTask(any()))
            .thenAnswer((_) async => Right(task));

        final result = await useCase(task);

        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not be left'),
          (createdTask) {
            expect(createdTask.priority, priority);
          },
        );
      }
    });
  });
}
