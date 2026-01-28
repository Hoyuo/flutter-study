import 'package:core/core.dart';
import '../entities/entities.dart';
import '../repositories/repositories.dart';

/// Use case for updating an existing diary entry
class UpdateDiaryUseCase {
  final DiaryRepository _repository;

  UpdateDiaryUseCase(this._repository);

  /// Execute the use case to update a diary entry
  /// Returns [Either] [Failure] or the updated [DiaryEntry]
  Future<Either<Failure, DiaryEntry>> call(DiaryEntry entry) {
    return _repository.updateDiary(entry);
  }
}
