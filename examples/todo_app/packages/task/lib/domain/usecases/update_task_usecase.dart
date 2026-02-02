import 'package:core/core.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Use case for updating an existing task
class UpdateTaskUseCase {
  final TaskRepository _repository;

  const UpdateTaskUseCase(this._repository);

  /// Execute the use case
  ///
  /// [task] The task with updated data
  /// Returns [Right(Task)] with the updated task, [Left(Failure)] on error
  Future<Either<Failure, Task>> call(Task task) {
    // Validate task
    if (task.id.isEmpty) {
      return Future.value(
        Left(Failure.validation(message: 'Task ID cannot be empty')),
      );
    }

    if (task.title.trim().isEmpty) {
      return Future.value(
        Left(Failure.validation(message: 'Task title cannot be empty')),
      );
    }

    return _repository.updateTask(task);
  }
}
