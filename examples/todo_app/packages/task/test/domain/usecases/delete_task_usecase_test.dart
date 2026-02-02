import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart' as fp;
import 'package:core/core.dart';
import 'package:task/domain/repositories/task_repository.dart';
import 'package:task/domain/usecases/delete_task_usecase.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late MockTaskRepository mockRepository;
  late DeleteTaskUseCase useCase;

  setUp(() {
    mockRepository = MockTaskRepository();
    useCase = DeleteTaskUseCase(mockRepository);
  });

  group('DeleteTaskUseCase', () {
    test('should delete task from repository', () async {
      // arrange
      const taskId = '1';
      when(() => mockRepository.deleteTask(taskId))
          .thenAnswer((_) async => Right(fp.unit));

      // act
      final result = await useCase(taskId);

      // assert
      expect(result, Right(fp.unit));
      verify(() => mockRepository.deleteTask(taskId)).called(1);
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
      verifyNever(() => mockRepository.deleteTask(taskId));
    });

    test('should return failure when task does not exist', () async {
      // arrange
      const taskId = 'non-existent';
      final failure = Failure.notFound(message: 'Task not found');
      when(() => mockRepository.deleteTask(taskId))
          .thenAnswer((_) async => Left(failure));

      // act
      final result = await useCase(taskId);

      // assert
      expect(result, Left(failure));
      verify(() => mockRepository.deleteTask(taskId)).called(1);
    });

    test('should return failure when repository fails', () async {
      // arrange
      const taskId = '1';
      final failure = Failure.unknown(message: 'Database error');
      when(() => mockRepository.deleteTask(taskId))
          .thenAnswer((_) async => Left(failure));

      // act
      final result = await useCase(taskId);

      // assert
      expect(result, Left(failure));
    });

    test('should handle multiple delete operations', () async {
      // arrange
      final taskIds = ['1', '2', '3'];
      for (final id in taskIds) {
        when(() => mockRepository.deleteTask(id))
            .thenAnswer((_) async => Right(fp.unit));
      }

      // act
      for (final id in taskIds) {
        final result = await useCase(id);
        expect(result, Right(fp.unit));
      }

      // assert
      for (final id in taskIds) {
        verify(() => mockRepository.deleteTask(id)).called(1);
      }
    });

    test('should handle UUID-format task ids', () async {
      // arrange
      const taskId = '550e8400-e29b-41d4-a716-446655440000';
      when(() => mockRepository.deleteTask(taskId))
          .thenAnswer((_) async => Right(fp.unit));

      // act
      final result = await useCase(taskId);

      // assert
      expect(result, Right(fp.unit));
      verify(() => mockRepository.deleteTask(taskId)).called(1);
    });
  });
}
