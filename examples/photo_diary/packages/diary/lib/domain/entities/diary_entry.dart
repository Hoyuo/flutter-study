import 'package:core/core.dart';
import 'tag.dart';

part 'diary_entry.freezed.dart';

/// Diary entry entity representing a single diary post
@freezed
abstract class DiaryEntry with _$DiaryEntry {
  const factory DiaryEntry({
    required String id,
    required String userId,
    required String title,
    required String content,
    @Default([]) List<String> photoUrls,
    @Default([]) List<Tag> tags,
    WeatherInfo? weather,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(SyncStatus.pending) SyncStatus syncStatus,
  }) = _DiaryEntry;
}
