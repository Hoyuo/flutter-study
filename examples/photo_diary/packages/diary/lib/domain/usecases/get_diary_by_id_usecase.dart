import 'package:core/core.dart';
import '../entities/entities.dart';
import '../repositories/repositories.dart';

/// Use case for retrieving a single diary entry by ID
class GetDiaryByIdUseCase {
  final DiaryRepository _repository;

  GetDiaryByIdUseCase(this._repository);

  /// Execute the use case to get a diary entry by ID
  /// Returns [Either] [Failure] or the [DiaryEntry]
  Future<Either<Failure, DiaryEntry>> call(String id) {
    return _repository.getDiaryById(id);
  }
}
