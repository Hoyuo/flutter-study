import 'package:core/core.dart';
import '../entities/task.dart';
import '../repositories/task_repository.dart';

/// Use case for searching tasks by query
class SearchTasksUseCase {
  final TaskRepository _repository;

  const SearchTasksUseCase(this._repository);

  /// Execute the use case
  ///
  /// [query] The search query string
  /// Returns [Right(List<Task>)] on success, [Left(Failure)] on error
  Future<Either<Failure, List<Task>>> call(String query) {
    // Empty query returns empty list (not an error)
    if (query.trim().isEmpty) {
      return Future.value(const Right([]));
    }
    return _repository.searchTasks(query.trim());
  }
}
