import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart' as fp;
import 'package:core/core.dart';
import 'package:task/data/datasources/task_local_datasource.dart';
import 'package:task/data/models/task_model.dart';
import 'package:task/data/repositories/task_repository_impl.dart';
import 'package:task/domain/entities/task.dart';
import 'package:task/domain/usecases/get_tasks_params.dart';

class MockTaskLocalDataSource extends Mock implements TaskLocalDataSource {}

void main() {
  late MockTaskLocalDataSource mockDataSource;
  late TaskRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockTaskLocalDataSource();
    repository = TaskRepositoryImpl(mockDataSource);
  });

  setUpAll(() {
    registerFallbackValue(TaskModel());
    registerFallbackValue(const GetTasksParams.defaults());
  });

  final now = DateTime(2024, 1, 1);

  TaskModel createTaskModel({
    String id = '1',
    String title = 'Test Task',
    String description = '',
    bool isCompleted = false,
    Priority priority = Priority.medium,
    DateTime? dueDate,
    String? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel()
      ..id = id
      ..title = title
      ..description = description
      ..isCompleted = isCompleted
      ..priority = priority
      ..dueDate = dueDate
      ..categoryId = categoryId
      ..createdAt = createdAt ?? now
      ..updatedAt = updatedAt ?? now;
  }

  group('TaskRepositoryImpl', () {
    group('getTask', () {
      test('should return task when it exists', () async {
        // arrange
        const taskId = '1';
        final model = createTaskModel();
        when(() => mockDataSource.getTask(taskId))
            .thenAnswer((_) async => model);

        // act
        final result = await repository.getTask(taskId);

        // assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not be left'),
          (task) {
            expect(task.id, '1');
            expect(task.title, 'Test Task');
          },
        );
        verify(() => mockDataSource.getTask(taskId)).called(1);
      });

      test('should return not found failure when task does not exist', () async {
        // arrange
        const taskId = 'non-existent';
        when(() => mockDataSource.getTask(taskId))
            .thenAnswer((_) async => null);

        // act
        final result = await repository.getTask(taskId);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure.message, 'Task not found');
          },
          (r) => fail('Should not be right'),
        );
      });

      test('should return unknown failure when datasource throws', () async {
        // arrange
        const taskId = '1';
        when(() => mockDataSource.getTask(taskId))
            .thenThrow(Exception('Database error'));

        // act
        final result = await repository.getTask(taskId);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure.message, contains('Failed to get task'));
          },
          (r) => fail('Should not be right'),
        );
      });
    });

    group('getTasks', () {
      test('should return list of tasks', () async {
        // arrange
        const params = GetTasksParams.defaults();
        final models = [
          createTaskModel(id: '1', title: 'Task 1'),
          createTaskModel(id: '2', title: 'Task 2'),
        ];
        when(() => mockDataSource.getTasks(any()))
            .thenAnswer((_) async => models);

        // act
        final result = await repository.getTasks(params);

        // assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not be left'),
          (tasks) {
            expect(tasks.length, 2);
            expect(tasks[0].id, '1');
            expect(tasks[1].id, '2');
          },
        );
      });

      test('should return empty list when no tasks', () async {
        // arrange
        const params = GetTasksParams.defaults();
        when(() => mockDataSource.getTasks(any()))
            .thenAnswer((_) async => <TaskModel>[]);

        // act
        final result = await repository.getTasks(params);

        // assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should be right'),
          (tasks) => expect(tasks, isEmpty),
        );
      });

      test('should pass params to datasource', () async {
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
        when(() => mockDataSource.getTasks(params))
            .thenAnswer((_) async => []);

        // act
        await repository.getTasks(params);

        // assert
        verify(() => mockDataSource.getTasks(params)).called(1);
      });

      test('should return unknown failure when datasource throws', () async {
        // arrange
        const params = GetTasksParams.defaults();
        when(() => mockDataSource.getTasks(any()))
            .thenThrow(Exception('Database error'));

        // act
        final result = await repository.getTasks(params);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure.message, contains('Failed to get tasks'));
          },
          (r) => fail('Should not be right'),
        );
      });
    });

    group('createTask', () {
      test('should create task when it does not exist', () async {
        // arrange
        final task = Task(
          id: '1',
          title: 'New Task',
          createdAt: now,
          updatedAt: now,
        );
        when(() => mockDataSource.taskExists('1'))
            .thenAnswer((_) async => false);
        when(() => mockDataSource.saveTask(any()))
            .thenAnswer((_) async {});

        // act
        final result = await repository.createTask(task);

        // assert
        expect(result, Right(task));
        verify(() => mockDataSource.taskExists('1')).called(1);
        verify(() => mockDataSource.saveTask(any())).called(1);
      });

      test('should return validation failure when task already exists', () async {
        // arrange
        final task = Task(
          id: '1',
          title: 'Existing Task',
          createdAt: now,
          updatedAt: now,
        );
        when(() => mockDataSource.taskExists('1'))
            .thenAnswer((_) async => true);

        // act
        final result = await repository.createTask(task);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure.message, contains('already exists'));
          },
          (r) => fail('Should not be right'),
        );
        verifyNever(() => mockDataSource.saveTask(any()));
      });

      test('should return unknown failure when datasource throws', () async {
        // arrange
        final task = Task(
          id: '1',
          title: 'New Task',
          createdAt: now,
          updatedAt: now,
        );
        when(() => mockDataSource.taskExists('1'))
            .thenThrow(Exception('Database error'));

        // act
        final result = await repository.createTask(task);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure.message, contains('Failed to create task'));
          },
          (r) => fail('Should not be right'),
        );
      });
    });

    group('updateTask', () {
      test('should update task when it exists', () async {
        // arrange
        final task = Task(
          id: '1',
          title: 'Updated Task',
          createdAt: now,
          updatedAt: now,
        );
        when(() => mockDataSource.taskExists('1'))
            .thenAnswer((_) async => true);
        when(() => mockDataSource.saveTask(any()))
            .thenAnswer((_) async {});

        // act
        final result = await repository.updateTask(task);

        // assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not be left'),
          (updatedTask) {
            expect(updatedTask.id, task.id);
            expect(updatedTask.title, task.title);
            // updatedAt should be updated to current time
            expect(updatedTask.updatedAt.isAfter(task.updatedAt) ||
                   updatedTask.updatedAt.isAtSameMomentAs(task.updatedAt), true);
          },
        );
        verify(() => mockDataSource.taskExists('1')).called(1);
        verify(() => mockDataSource.saveTask(any())).called(1);
      });

      test('should return not found failure when task does not exist', () async {
        // arrange
        final task = Task(
          id: 'non-existent',
          title: 'Updated Task',
          createdAt: now,
          updatedAt: now,
        );
        when(() => mockDataSource.taskExists('non-existent'))
            .thenAnswer((_) async => false);

        // act
        final result = await repository.updateTask(task);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure.message, 'Task not found');
          },
          (r) => fail('Should not be right'),
        );
        verifyNever(() => mockDataSource.saveTask(any()));
      });

      test('should return unknown failure when datasource throws', () async {
        // arrange
        final task = Task(
          id: '1',
          title: 'Updated Task',
          createdAt: now,
          updatedAt: now,
        );
        when(() => mockDataSource.taskExists('1'))
            .thenThrow(Exception('Database error'));

        // act
        final result = await repository.updateTask(task);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure.message, contains('Failed to update task'));
          },
          (r) => fail('Should not be right'),
        );
      });
    });

    group('deleteTask', () {
      test('should delete task when it exists', () async {
        // arrange
        const taskId = '1';
        when(() => mockDataSource.taskExists(taskId))
            .thenAnswer((_) async => true);
        when(() => mockDataSource.deleteTask(taskId))
            .thenAnswer((_) async {});

        // act
        final result = await repository.deleteTask(taskId);

        // assert
        expect(result, Right(fp.unit));
        verify(() => mockDataSource.taskExists(taskId)).called(1);
        verify(() => mockDataSource.deleteTask(taskId)).called(1);
      });

      test('should return not found failure when task does not exist', () async {
        // arrange
        const taskId = 'non-existent';
        when(() => mockDataSource.taskExists(taskId))
            .thenAnswer((_) async => false);

        // act
        final result = await repository.deleteTask(taskId);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure.message, 'Task not found');
          },
          (r) => fail('Should not be right'),
        );
        verifyNever(() => mockDataSource.deleteTask(any()));
      });

      test('should return unknown failure when datasource throws', () async {
        // arrange
        const taskId = '1';
        when(() => mockDataSource.taskExists(taskId))
            .thenThrow(Exception('Database error'));

        // act
        final result = await repository.deleteTask(taskId);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure.message, contains('Failed to delete task'));
          },
          (r) => fail('Should not be right'),
        );
      });
    });

    group('toggleTaskCompletion', () {
      test('should toggle completion from false to true', () async {
        // arrange
        const taskId = '1';
        final model = createTaskModel(isCompleted: false);
        when(() => mockDataSource.getTask(taskId))
            .thenAnswer((_) async => model);
        when(() => mockDataSource.saveTask(any()))
            .thenAnswer((_) async {});

        // act
        final result = await repository.toggleTaskCompletion(taskId);

        // assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not be left'),
          (task) {
            expect(task.isCompleted, true);
          },
        );
        verify(() => mockDataSource.getTask(taskId)).called(1);
        verify(() => mockDataSource.saveTask(any())).called(1);
      });

      test('should toggle completion from true to false', () async {
        // arrange
        const taskId = '1';
        final model = createTaskModel(isCompleted: true);
        when(() => mockDataSource.getTask(taskId))
            .thenAnswer((_) async => model);
        when(() => mockDataSource.saveTask(any()))
            .thenAnswer((_) async {});

        // act
        final result = await repository.toggleTaskCompletion(taskId);

        // assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not be left'),
          (task) {
            expect(task.isCompleted, false);
          },
        );
      });

      test('should update updatedAt timestamp', () async {
        // arrange
        const taskId = '1';
        final model = createTaskModel(updatedAt: now);
        when(() => mockDataSource.getTask(taskId))
            .thenAnswer((_) async => model);
        when(() => mockDataSource.saveTask(any()))
            .thenAnswer((_) async {});

        // act
        final result = await repository.toggleTaskCompletion(taskId);

        // assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not be left'),
          (task) {
            expect(task.updatedAt.isAfter(now) ||
                   task.updatedAt.isAtSameMomentAs(now), true);
          },
        );
      });

      test('should return not found failure when task does not exist', () async {
        // arrange
        const taskId = 'non-existent';
        when(() => mockDataSource.getTask(taskId))
            .thenAnswer((_) async => null);

        // act
        final result = await repository.toggleTaskCompletion(taskId);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure.message, 'Task not found');
          },
          (r) => fail('Should not be right'),
        );
        verifyNever(() => mockDataSource.saveTask(any()));
      });

      test('should return unknown failure when datasource throws', () async {
        // arrange
        const taskId = '1';
        when(() => mockDataSource.getTask(taskId))
            .thenThrow(Exception('Database error'));

        // act
        final result = await repository.toggleTaskCompletion(taskId);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure.message, contains('Failed to toggle task completion'));
          },
          (r) => fail('Should not be right'),
        );
      });
    });

    group('searchTasks', () {
      test('should return matching tasks', () async {
        // arrange
        const query = 'test';
        final models = [
          createTaskModel(id: '1', title: 'Test Task 1'),
          createTaskModel(id: '2', title: 'Test Task 2'),
        ];
        when(() => mockDataSource.searchTasks(query))
            .thenAnswer((_) async => models);

        // act
        final result = await repository.searchTasks(query);

        // assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should not be left'),
          (tasks) {
            expect(tasks.length, 2);
            expect(tasks[0].title, 'Test Task 1');
            expect(tasks[1].title, 'Test Task 2');
          },
        );
        verify(() => mockDataSource.searchTasks(query)).called(1);
      });

      test('should return empty list when no matches', () async {
        // arrange
        const query = 'nonexistent';
        when(() => mockDataSource.searchTasks(query))
            .thenAnswer((_) async => <TaskModel>[]);

        // act
        final result = await repository.searchTasks(query);

        // assert
        expect(result.isRight(), true);
        result.fold(
          (l) => fail('Should be right'),
          (tasks) => expect(tasks, isEmpty),
        );
      });

      test('should return unknown failure when datasource throws', () async {
        // arrange
        const query = 'test';
        when(() => mockDataSource.searchTasks(query))
            .thenThrow(Exception('Database error'));

        // act
        final result = await repository.searchTasks(query);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure.message, contains('Failed to search tasks'));
          },
          (r) => fail('Should not be right'),
        );
      });
    });

    group('getTaskCountByCategory', () {
      test('should return count of tasks in category', () async {
        // arrange
        const categoryId = 'cat-1';
        when(() => mockDataSource.getTaskCountByCategory(categoryId))
            .thenAnswer((_) async => 5);

        // act
        final result = await repository.getTaskCountByCategory(categoryId);

        // assert
        expect(result, const Right<Failure, int>(5));
        verify(() => mockDataSource.getTaskCountByCategory(categoryId)).called(1);
      });

      test('should return 0 when no tasks in category', () async {
        // arrange
        const categoryId = 'empty-cat';
        when(() => mockDataSource.getTaskCountByCategory(categoryId))
            .thenAnswer((_) async => 0);

        // act
        final result = await repository.getTaskCountByCategory(categoryId);

        // assert
        expect(result, const Right<Failure, int>(0));
      });

      test('should return unknown failure when datasource throws', () async {
        // arrange
        const categoryId = 'cat-1';
        when(() => mockDataSource.getTaskCountByCategory(categoryId))
            .thenThrow(Exception('Database error'));

        // act
        final result = await repository.getTaskCountByCategory(categoryId);

        // assert
        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure.message, contains('Failed to get task count'));
          },
          (r) => fail('Should not be right'),
        );
      });
    });
  });
}
