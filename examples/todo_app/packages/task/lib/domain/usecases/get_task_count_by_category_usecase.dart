import 'package:core/core.dart';
import '../repositories/task_repository.dart';

/// Use case for getting task count in a category
class GetTaskCountByCategoryUseCase {
  final TaskRepository _repository;

  const GetTaskCountByCategoryUseCase(this._repository);

  /// Execute the use case
  ///
  /// [categoryId] The category ID to count tasks for
  /// Returns [Right(int)] with count, [Left(Failure)] on error
  Future<Either<Failure, int>> call(String categoryId) {
    if (categoryId.isEmpty) {
      return Future.value(
        Left(Failure.validation(message: 'Category ID cannot be empty')),
      );
    }
    return _repository.getTaskCountByCategory(categoryId);
  }
}
