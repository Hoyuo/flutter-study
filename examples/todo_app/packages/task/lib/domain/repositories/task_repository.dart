import 'package:core/core.dart';
import '../entities/task.dart';
import '../usecases/get_tasks_params.dart';

/// Repository interface for task data operations
abstract class TaskRepository {
  /// Get a single task by ID
  ///
  /// Returns [Right(Task)] if found, [Left(Failure)] otherwise
  Future<Either<Failure, Task>> getTask(String id);

  /// Get list of tasks with filtering and pagination
  ///
  /// Returns [Right(List<Task>)] on success, [Left(Failure)] on error
  Future<Either<Failure, List<Task>>> getTasks(GetTasksParams params);

  /// Create a new task
  ///
  /// Returns [Right(Task)] with the created task, [Left(Failure)] on error
  Future<Either<Failure, Task>> createTask(Task task);

  /// Update an existing task
  ///
  /// Returns [Right(Task)] with the updated task, [Left(Failure)] on error
  Future<Either<Failure, Task>> updateTask(Task task);

  /// Delete a task by ID
  ///
  /// Returns [Right(Unit)] on success, [Left(Failure)] on error
  Future<Either<Failure, Unit>> deleteTask(String id);

  /// Toggle task completion status
  ///
  /// Returns [Right(Task)] with updated task, [Left(Failure)] on error
  Future<Either<Failure, Task>> toggleTaskCompletion(String id);

  /// Search tasks by query string
  ///
  /// Searches in title and description fields
  /// Returns [Right(List<Task>)] on success, [Left(Failure)] on error
  Future<Either<Failure, List<Task>>> searchTasks(String query);

  /// Get count of tasks in a specific category
  ///
  /// Returns [Right(int)] with count, [Left(Failure)] on error
  Future<Either<Failure, int>> getTaskCountByCategory(String categoryId);
}
