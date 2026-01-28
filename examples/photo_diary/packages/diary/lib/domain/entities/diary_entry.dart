import 'package:core/core.dart';
import 'tag.dart';

part 'diary_entry.freezed.dart';
part 'diary_entry.g.dart';

/// Diary entry entity representing a single diary post
@freezed
class DiaryEntry with _$DiaryEntry {
  const factory DiaryEntry({
    required String id,
    required String userId,
    required String title,
    required String content,
    @Default([]) List<String> photoUrls,
    @Default([]) List<Tag> tags,
    @JsonKey(fromJson: _weatherInfoFromJson, toJson: _weatherInfoToJson) @Default(null) WeatherInfo? weather,
    required DateTime createdAt,
    required DateTime updatedAt,
    @JsonKey(fromJson: _syncStatusFromJson, toJson: _syncStatusToJson) @Default(SyncStatus.pending) SyncStatus syncStatus,
  }) = _DiaryEntry;

  factory DiaryEntry.fromJson(Map<String, dynamic> json) =>
      _$DiaryEntryFromJson(json);
}

/// Helper function to deserialize WeatherInfo from JSON
WeatherInfo? _weatherInfoFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  return WeatherInfo.fromJson(json);
}

/// Helper function to serialize WeatherInfo to JSON
Map<String, dynamic>? _weatherInfoToJson(WeatherInfo? weather) {
  return weather?.toJson();
}

/// Helper function to deserialize SyncStatus from JSON
SyncStatus _syncStatusFromJson(String json) {
  return SyncStatus.values.firstWhere(
    (e) => e.name == json,
    orElse: () => SyncStatus.pending,
  );
}

/// Helper function to serialize SyncStatus to JSON
String _syncStatusToJson(SyncStatus status) {
  return status.name;
}
