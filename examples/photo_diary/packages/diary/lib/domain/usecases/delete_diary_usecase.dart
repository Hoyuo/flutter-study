import 'package:core/core.dart';
import '../repositories/repositories.dart';

/// Use case for deleting a diary entry
class DeleteDiaryUseCase {
  final DiaryRepository _repository;

  DeleteDiaryUseCase(this._repository);

  /// Execute the use case to delete a diary entry
  /// Returns [Either] [Failure] or [Unit] on success
  Future<Either<Failure, Unit>> call(String id) {
    return _repository.deleteDiary(id);
  }
}
