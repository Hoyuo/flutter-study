import '../models/models.dart';

/// Local data source interface for diary caching
/// This can be implemented using Hive, Drift, or SharedPreferences
abstract class DiaryLocalDataSource {
  /// Cache a diary entry locally
  /// Throws [Exception] on error
  Future<void> cacheDiary(DiaryEntryModel entry);

  /// Cache multiple diary entries
  /// Throws [Exception] on error
  Future<void> cacheDiaries(List<DiaryEntryModel> entries);

  /// Get cached diary entries
  /// Returns empty list if no cached entries
  Future<List<DiaryEntryModel>> getCachedDiaries({
    required String userId,
    int limit = 20,
    int offset = 0,
  });

  /// Get a cached diary entry by ID
  /// Returns null if not found
  Future<DiaryEntryModel?> getCachedDiaryById(String diaryId);

  /// Update a cached diary entry
  /// Throws [Exception] on error
  Future<void> updateCachedDiary(DiaryEntryModel entry);

  /// Delete a cached diary entry
  /// Throws [Exception] on error
  Future<void> deleteCachedDiary(String diaryId);

  /// Clear all cached diary entries
  /// Throws [Exception] on error
  Future<void> clearCache();

  /// Get entries that are pending sync
  /// Returns list of entries with syncStatus != synced
  Future<List<DiaryEntryModel>> getPendingSyncEntries(String userId);
}
