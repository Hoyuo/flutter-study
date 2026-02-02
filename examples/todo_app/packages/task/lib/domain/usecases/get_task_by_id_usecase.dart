import 'package:core/core.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Use case for retrieving a single task by ID
class GetTaskByIdUseCase {
  final TaskRepository _repository;

  const GetTaskByIdUseCase(this._repository);

  /// Execute the use case
  ///
  /// [id] The task ID to retrieve
  /// Returns [Right(Task)] if found, [Left(Failure)] otherwise
  Future<Either<Failure, Task>> call(String id) {
    if (id.isEmpty) {
      return Future.value(
        Left(Failure.validation(message: 'Task ID cannot be empty')),
      );
    }
    return _repository.getTask(id);
  }
}
