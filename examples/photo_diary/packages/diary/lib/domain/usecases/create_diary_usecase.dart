import 'package:core/core.dart';
import '../entities/entities.dart';
import '../repositories/repositories.dart';

/// Use case for creating a new diary entry
class CreateDiaryUseCase implements UseCase<DiaryEntry, DiaryEntry> {
  final DiaryRepository _repository;

  CreateDiaryUseCase(this._repository);

  /// Execute the use case to create a diary entry
  /// Returns [Either] [Failure] or the created [DiaryEntry]
  @override
  Future<Either<Failure, DiaryEntry>> call(DiaryEntry entry) {
    return _repository.createDiary(entry);
  }
}
