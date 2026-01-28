import '../models/models.dart';

/// Remote data source interface for diary operations
abstract class DiaryRemoteDataSource {
  /// Create a new diary entry in Firestore
  /// Throws [Exception] on error
  Future<DiaryEntryModel> createDiary(DiaryEntryModel entry);

  /// Get paginated list of diary entries
  /// [userId] - ID of the user whose diaries to fetch
  /// [limit] - Maximum number of entries to return
  /// [startAfterDocId] - Document ID to start after (for pagination)
  /// Throws [Exception] on error
  Future<List<DiaryEntryModel>> getDiaries({
    required String userId,
    int limit = 20,
    String? startAfterDocId,
  });

  /// Get a single diary entry by ID
  /// [userId] - ID of the user who owns the diary
  /// [diaryId] - ID of the diary entry to fetch
  /// Throws [Exception] on error
  Future<DiaryEntryModel> getDiaryById({
    required String userId,
    required String diaryId,
  });

  /// Update an existing diary entry
  /// Throws [Exception] on error
  Future<DiaryEntryModel> updateDiary(DiaryEntryModel entry);

  /// Delete a diary entry
  /// [userId] - ID of the user who owns the diary
  /// [diaryId] - ID of the diary entry to delete
  /// Throws [Exception] on error
  Future<void> deleteDiary({
    required String userId,
    required String diaryId,
  });

  /// Search diary entries by query
  /// [userId] - ID of the user whose diaries to search
  /// [query] - Search term to match in title or content
  /// [limit] - Maximum number of results to return
  /// Throws [Exception] on error
  Future<List<DiaryEntryModel>> searchDiaries({
    required String userId,
    required String query,
    int limit = 20,
  });

  /// Get diary entries filtered by tag
  /// [userId] - ID of the user whose diaries to fetch
  /// [tagId] - ID of the tag to filter by
  /// [limit] - Maximum number of entries to return
  /// [startAfterDocId] - Document ID to start after (for pagination)
  /// Throws [Exception] on error
  Future<List<DiaryEntryModel>> getDiariesByTag({
    required String userId,
    required String tagId,
    int limit = 20,
    String? startAfterDocId,
  });
}
