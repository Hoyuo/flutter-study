import 'package:core/core.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';
import 'get_tasks_params.dart';

/// Use case for retrieving tasks with filtering and pagination
class GetTasksUseCase {
  final TaskRepository _repository;

  const GetTasksUseCase(this._repository);

  /// Execute the use case
  ///
  /// [params] Parameters for filtering, sorting and pagination
  /// Returns [Right(List<Task>)] on success, [Left(Failure)] on error
  Future<Either<Failure, List<Task>>> call(GetTasksParams params) {
    return _repository.getTasks(params);
  }
}
