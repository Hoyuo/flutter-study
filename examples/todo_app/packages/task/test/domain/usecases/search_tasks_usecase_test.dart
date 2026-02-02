import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:core/core.dart';
import 'package:task/domain/entities/task.dart';
import 'package:task/domain/repositories/task_repository.dart';
import 'package:task/domain/usecases/search_tasks_usecase.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;
  late SearchTasksUseCase useCase;

  setUp(() {
    mockRepository = MockTaskRepository();
    useCase = SearchTasksUseCase(mockRepository);
  });

  final now = DateTime(2024, 1, 1);
  final task1 = Task(
    id: '1',
    title: 'Buy groceries',
    description: 'Milk, eggs, bread',
    createdAt: now,
    updatedAt: now,
  );
  final task2 = Task(
    id: '2',
    title: 'Write report',
    description: 'Quarterly sales report',
    createdAt: now,
    updatedAt: now,
  );

  group('SearchTasksUseCase', () {
    test('should search tasks in repository', () async {
      // arrange
      const query = 'groceries';
      final tasks = [task1];
      when(() => mockRepository.searchTasks(query))
          .thenAnswer((_) async => Right(tasks));

      // act
      final result = await useCase(query);

      // assert
      expect(result, Right(tasks));
      verify(() => mockRepository.searchTasks(query)).called(1);
    });

    test('should return empty list when query is empty', () async {
      // arrange
      const query = '';

      // act
      final result = await useCase(query);

      // assert
      expect(result, const Right<Failure, List<Task>>([]));

      verifyNever(() => mockRepository.searchTasks(any()));
    });

    test('should return empty list when query is only whitespace', () async {
      // arrange
      const query = '   ';

      // act
      final result = await useCase(query);

      // assert
      expect(result, const Right<Failure, List<Task>>([]));

      verifyNever(() => mockRepository.searchTasks(any()));
    });

    test('should trim query before searching', () async {
      // arrange
      const query = '  groceries  ';
      when(() => mockRepository.searchTasks('groceries'))
          .thenAnswer((_) async => Right([task1]));

      // act
      final result = await useCase(query);

      // assert
      expect(result.isRight(), true);
      verify(() => mockRepository.searchTasks('groceries')).called(1);
    });

    test('should return multiple matching tasks', () async {
      // arrange
      const query = 'report';
      final tasks = [task1, task2];
      when(() => mockRepository.searchTasks(query))
          .thenAnswer((_) async => Right(tasks));

      // act
      final result = await useCase(query);

      // assert
      expect(result, Right<Failure, List<Task>>(tasks));
    });

    test('should return empty list when no tasks match', () async {
      // arrange
      const query = 'nonexistent';
      when(() => mockRepository.searchTasks(query))
          .thenAnswer((_) async => const Right([]));

      // act
      final result = await useCase(query);

      // assert
      expect(result, const Right<Failure, List<Task>>([]));

    });

    test('should return failure when repository fails', () async {
      // arrange
      const query = 'groceries';
      final failure = Failure.unknown(message: 'Database error');
      when(() => mockRepository.searchTasks(query))
          .thenAnswer((_) async => Left(failure));

      // act
      final result = await useCase(query);

      // assert
      expect(result, Left(failure));
    });

    test('should search in task titles', () async {
      // arrange
      const query = 'groceries';
      when(() => mockRepository.searchTasks(query))
          .thenAnswer((_) async => Right([task1]));

      // act
      final result = await useCase(query);

      // assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not be left'),
        (tasks) {
          expect(tasks.length, 1);
          expect(tasks.first.title.toLowerCase(), contains(query.toLowerCase()));
        },
      );
    });

    test('should search in task descriptions', () async {
      // arrange
      const query = 'quarterly';
      when(() => mockRepository.searchTasks(query))
          .thenAnswer((_) async => Right([task2]));

      // act
      final result = await useCase(query);

      // assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not be left'),
        (tasks) {
          expect(tasks.length, 1);
          expect(tasks.first.description.toLowerCase(), contains(query.toLowerCase()));
        },
      );
    });

    test('should handle case-insensitive search', () async {
      // arrange
      const query = 'GROCERIES';
      when(() => mockRepository.searchTasks(query))
          .thenAnswer((_) async => Right([task1]));

      // act
      final result = await useCase(query);

      // assert
      expect(result.isRight(), true);
      verify(() => mockRepository.searchTasks(query)).called(1);
    });

    test('should handle partial matches', () async {
      // arrange
      const query = 'gro';
      when(() => mockRepository.searchTasks(query))
          .thenAnswer((_) async => Right([task1]));

      // act
      final result = await useCase(query);

      // assert
      expect(result.isRight(), true);
    });

    test('should handle special characters in query', () async {
      // arrange
      const query = 'task@123';
      when(() => mockRepository.searchTasks(query))
          .thenAnswer((_) async => const Right([]));

      // act
      final result = await useCase(query);

      // assert
      expect(result, const Right<Failure, List<Task>>([]));

      verify(() => mockRepository.searchTasks(query)).called(1);
    });

    test('should handle very long query strings', () async {
      // arrange
      final query = 'a' * 1000;
      when(() => mockRepository.searchTasks(query))
          .thenAnswer((_) async => const Right([]));

      // act
      final result = await useCase(query);

      // assert
      expect(result, const Right<Failure, List<Task>>([]));

      verify(() => mockRepository.searchTasks(query)).called(1);
    });

    test('should handle numeric queries', () async {
      // arrange
      const query = '123';
      when(() => mockRepository.searchTasks(query))
          .thenAnswer((_) async => const Right([]));

      // act
      final result = await useCase(query);

      // assert
      expect(result, const Right<Failure, List<Task>>([]));

      verify(() => mockRepository.searchTasks(query)).called(1);
    });
  });
}
