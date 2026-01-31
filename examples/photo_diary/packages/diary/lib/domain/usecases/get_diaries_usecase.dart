import 'package:core/core.dart';
import '../entities/entities.dart';
import '../repositories/repositories.dart';

/// Parameters for getting diaries with pagination
class GetDiariesParams {
  final int limit;
  final String? lastEntryId;

  const GetDiariesParams({
    this.limit = 20,
    this.lastEntryId,
  });
}

/// Use case for retrieving paginated diary entries
class GetDiariesUseCase implements UseCase<List<DiaryEntry>, GetDiariesParams> {
  final DiaryRepository _repository;

  GetDiariesUseCase(this._repository);

  /// Execute the use case to get diary entries
  /// Returns [Either] [Failure] or list of [DiaryEntry]
  @override
  Future<Either<Failure, List<DiaryEntry>>> call(GetDiariesParams params) {
    return _repository.getDiaries(
      limit: params.limit,
      lastEntryId: params.lastEntryId,
    );
  }
}
