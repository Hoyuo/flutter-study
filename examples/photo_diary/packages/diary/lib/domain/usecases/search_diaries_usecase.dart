import 'package:core/core.dart';
import '../entities/entities.dart';
import '../repositories/repositories.dart';

/// Parameters for searching diaries
class SearchDiariesParams {
  final String query;
  final int limit;

  const SearchDiariesParams({
    required this.query,
    this.limit = 20,
  });
}

/// Use case for searching diary entries
class SearchDiariesUseCase {
  final DiaryRepository _repository;

  SearchDiariesUseCase(this._repository);

  /// Execute the use case to search diary entries
  /// Returns [Either] [Failure] or list of matching [DiaryEntry]
  Future<Either<Failure, List<DiaryEntry>>> call(SearchDiariesParams params) {
    return _repository.searchDiaries(
      query: params.query,
      limit: params.limit,
    );
  }
}
