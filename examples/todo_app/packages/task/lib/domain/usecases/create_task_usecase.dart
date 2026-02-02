import 'package:core/core.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Use case for creating a new task
class CreateTaskUseCase {
  final TaskRepository _repository;

  const CreateTaskUseCase(this._repository);

  /// Execute the use case
  ///
  /// [task] The task to create
  /// Returns [Right(Task)] with the created task, [Left(Failure)] on error
  Future<Either<Failure, Task>> call(Task task) {
    // Validate task
    if (task.title.trim().isEmpty) {
      return Future.value(
        Left(Failure.validation(message: 'Task title cannot be empty')),
      );
    }

    return _repository.createTask(task);
  }
}
