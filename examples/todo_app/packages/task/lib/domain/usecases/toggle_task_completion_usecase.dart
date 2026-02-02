import 'package:core/core.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Use case for toggling task completion status
class ToggleTaskCompletionUseCase {
  final TaskRepository _repository;

  const ToggleTaskCompletionUseCase(this._repository);

  /// Execute the use case
  ///
  /// [id] The ID of the task to toggle
  /// Returns [Right(Task)] with updated task, [Left(Failure)] on error
  Future<Either<Failure, Task>> call(String id) {
    if (id.isEmpty) {
      return Future.value(
        Left(Failure.validation(message: 'Task ID cannot be empty')),
      );
    }
    return _repository.toggleTaskCompletion(id);
  }
}
