import 'package:core/core.dart';
import '../entities/entities.dart';

/// Repository interface for tag operations
abstract class TagRepository {
  /// Create a new tag
  /// Returns [Either] [Failure] or the created [Tag]
  Future<Either<Failure, Tag>> createTag(Tag tag);

  /// Get all tags for the current user
  /// Returns [Either] [Failure] or list of [Tag]
  Future<Either<Failure, List<Tag>>> getTags();

  /// Update an existing tag
  /// Returns [Either] [Failure] or the updated [Tag]
  Future<Either<Failure, Tag>> updateTag(Tag tag);

  /// Delete a tag
  /// Returns [Either] [Failure] or [Unit] on success
  Future<Either<Failure, Unit>> deleteTag(String id);
}
