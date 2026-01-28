import 'package:core/core.dart';
import '../entities/entities.dart';
import '../repositories/repositories.dart';

/// Use case for creating a new tag
class CreateTagUseCase {
  final TagRepository _repository;

  CreateTagUseCase(this._repository);

  /// Execute the use case to create a tag
  /// Returns [Either] [Failure] or the created [Tag]
  Future<Either<Failure, Tag>> call(Tag tag) {
    return _repository.createTag(tag);
  }
}
