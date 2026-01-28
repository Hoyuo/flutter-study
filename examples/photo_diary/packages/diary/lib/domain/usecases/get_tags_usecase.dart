import 'package:core/core.dart';
import '../entities/entities.dart';
import '../repositories/repositories.dart';

/// Use case for retrieving all tags
class GetTagsUseCase {
  final TagRepository _repository;

  GetTagsUseCase(this._repository);

  /// Execute the use case to get all tags
  /// Returns [Either] [Failure] or list of [Tag]
  Future<Either<Failure, List<Tag>>> call() {
    return _repository.getTags();
  }
}
