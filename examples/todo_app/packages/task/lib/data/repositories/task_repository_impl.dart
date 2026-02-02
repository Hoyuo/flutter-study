import 'package:core/core.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/usecases/get_tasks_params.dart';
import '../datasources/task_local_datasource.dart';
import '../models/task_model.dart';

/// Implementation of TaskRepository using local data source
class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource _localDataSource;

  const TaskRepositoryImpl(this._localDataSource);

  @override
  Future<Either<Failure, Task>> getTask(String id) async {
    try {
      final model = await _localDataSource.getTask(id);

      if (model == null) {
        return Left(Failure.notFound(message: 'Task not found'));
      }

      return Right(model.toEntity());
    } catch (e) {
      return Left(Failure.unknown(message: 'Failed to get task: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Task>>> getTasks(GetTasksParams params) async {
    try {
      final models = await _localDataSource.getTasks(params);
      final tasks = models.map((model) => model.toEntity()).toList();
      return Right(tasks);
    } catch (e) {
      return Left(Failure.unknown(message: 'Failed to get tasks: $e'));
    }
  }

  @override
  Future<Either<Failure, Task>> createTask(Task task) async {
    try {
      // Validate that task doesn't already exist
      final exists = await _localDataSource.taskExists(task.id);
      if (exists) {
        return Left(Failure.validation(message: 'Task with ID ${task.id} already exists'));
      }

      final model = TaskModel.fromEntity(task);
      await _localDataSource.saveTask(model);
      return Right(task);
    } catch (e) {
      return Left(Failure.unknown(message: 'Failed to create task: $e'));
    }
  }

  @override
  Future<Either<Failure, Task>> updateTask(Task task) async {
    try {
      // Validate that task exists
      final exists = await _localDataSource.taskExists(task.id);
      if (!exists) {
        return Left(Failure.notFound(message: 'Task not found'));
      }

      // Update timestamp
      final updatedTask = task.copyWith(updatedAt: DateTime.now());
      final model = TaskModel.fromEntity(updatedTask);
      await _localDataSource.saveTask(model);

      return Right(updatedTask);
    } catch (e) {
      return Left(Failure.unknown(message: 'Failed to update task: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTask(String id) async {
    try {
      // Validate that task exists
      final exists = await _localDataSource.taskExists(id);
      if (!exists) {
        return Left(Failure.notFound(message: 'Task not found'));
      }

      await _localDataSource.deleteTask(id);
      return Right(unit);
    } catch (e) {
      return Left(Failure.unknown(message: 'Failed to delete task: $e'));
    }
  }

  @override
  Future<Either<Failure, Task>> toggleTaskCompletion(String id) async {
    try {
      // Get current task
      final model = await _localDataSource.getTask(id);

      if (model == null) {
        return Left(Failure.notFound(message: 'Task not found'));
      }

      // Toggle completion and update timestamp
      final task = model.toEntity();
      final updatedTask = task.copyWith(
        isCompleted: !task.isCompleted,
        updatedAt: DateTime.now(),
      );

      // Save updated task
      final updatedModel = TaskModel.fromEntity(updatedTask);
      await _localDataSource.saveTask(updatedModel);

      return Right(updatedTask);
    } catch (e) {
      return Left(Failure.unknown(message: 'Failed to toggle task completion: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Task>>> searchTasks(String query) async {
    try {
      final models = await _localDataSource.searchTasks(query);
      final tasks = models.map((model) => model.toEntity()).toList();
      return Right(tasks);
    } catch (e) {
      return Left(Failure.unknown(message: 'Failed to search tasks: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getTaskCountByCategory(String categoryId) async {
    try {
      final count = await _localDataSource.getTaskCountByCategory(categoryId);
      return Right(count);
    } catch (e) {
      return Left(Failure.unknown(message: 'Failed to get task count: $e'));
    }
  }
}
