import 'package:core/core.dart';
import '../repositories/task_repository.dart';

/// Use case for deleting a task
class DeleteTaskUseCase {
  final TaskRepository _repository;

  const DeleteTaskUseCase(this._repository);

  /// Execute the use case
  ///
  /// [id] The ID of the task to delete
  /// Returns [Right(Unit)] on success, [Left(Failure)] on error
  Future<Either<Failure, Unit>> call(String id) {
    if (id.isEmpty) {
      return Future.value(
        Left(Failure.validation(message: 'Task ID cannot be empty')),
      );
    }
    return _repository.deleteTask(id);
  }
}
