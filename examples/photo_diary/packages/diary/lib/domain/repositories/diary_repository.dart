import 'package:core/core.dart';
import '../entities/entities.dart';

/// Repository interface for diary operations
abstract class DiaryRepository {
  /// Create a new diary entry
  /// Returns [Either] [Failure] or the created [DiaryEntry]
  Future<Either<Failure, DiaryEntry>> createDiary(DiaryEntry entry);

  /// Get paginated list of diary entries
  /// [limit] - Maximum number of entries to return
  /// [lastEntryId] - ID of the last entry from previous page (for pagination)
  /// Returns [Either] [Failure] or list of [DiaryEntry]
  Future<Either<Failure, List<DiaryEntry>>> getDiaries({
    int limit = 20,
    String? lastEntryId,
  });

  /// Get a single diary entry by ID
  /// Returns [Either] [Failure] or [DiaryEntry]
  Future<Either<Failure, DiaryEntry>> getDiaryById(String id);

  /// Update an existing diary entry
  /// Returns [Either] [Failure] or the updated [DiaryEntry]
  Future<Either<Failure, DiaryEntry>> updateDiary(DiaryEntry entry);

  /// Delete a diary entry
  /// Returns [Either] [Failure] or [Unit] on success
  Future<Either<Failure, Unit>> deleteDiary(String id);

  /// Search diary entries by query
  /// [query] - Search term to match in title or content
  /// [limit] - Maximum number of results to return
  /// Returns [Either] [Failure] or list of matching [DiaryEntry]
  Future<Either<Failure, List<DiaryEntry>>> searchDiaries({
    required String query,
    int limit = 20,
  });

  /// Get diary entries filtered by tag
  /// [tagId] - ID of the tag to filter by
  /// [limit] - Maximum number of entries to return
  /// [lastEntryId] - ID of the last entry from previous page (for pagination)
  /// Returns [Either] [Failure] or list of [DiaryEntry]
  Future<Either<Failure, List<DiaryEntry>>> getDiariesByTag({
    required String tagId,
    int limit = 20,
    String? lastEntryId,
  });
}
