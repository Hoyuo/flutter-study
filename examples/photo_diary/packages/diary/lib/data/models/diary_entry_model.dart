import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import '../../domain/entities/entities.dart';
import 'tag_model.dart';

part 'diary_entry_model.freezed.dart';
part 'diary_entry_model.g.dart';

/// Data model for diary entry with Firestore mapping
@freezed
class DiaryEntryModel with _$DiaryEntryModel {
  const DiaryEntryModel._();

  const factory DiaryEntryModel({
    required String id,
    required String userId,
    required String title,
    required String content,
    @Default([]) List<String> photoUrls,
    @Default([]) List<TagModel> tags,
    @JsonKey(fromJson: _weatherInfoFromJson, toJson: _weatherInfoToJson) @Default(null) WeatherInfo? weather,
    required DateTime createdAt,
    required DateTime updatedAt,
    @JsonKey(fromJson: _syncStatusFromJson, toJson: _syncStatusToJson) @Default(SyncStatus.pending) SyncStatus syncStatus,
  }) = _DiaryEntryModel;

  /// Create model from JSON
  factory DiaryEntryModel.fromJson(Map<String, dynamic> json) =>
      _$DiaryEntryModelFromJson(json);

  /// Create model from Firestore document
  factory DiaryEntryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DiaryEntryModel(
      id: doc.id,
      userId: data['userId'] as String,
      title: data['title'] as String,
      content: data['content'] as String,
      photoUrls: (data['photoUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      tags: (data['tags'] as List<dynamic>?)
              ?.map((e) => TagModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      weather: data['weather'] != null
          ? WeatherInfo.fromJson(data['weather'] as Map<String, dynamic>)
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == data['syncStatus'],
        orElse: () => SyncStatus.synced,
      ),
    );
  }

  /// Convert model to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'content': content,
      'photoUrls': photoUrls,
      'tags': tags.map((t) => t.toJson()).toList(),
      'weather': weather?.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'syncStatus': syncStatus.name,
    };
  }

  /// Convert model to domain entity
  DiaryEntry toEntity() {
    return DiaryEntry(
      id: id,
      userId: userId,
      title: title,
      content: content,
      photoUrls: photoUrls,
      tags: tags.map((t) => t.toEntity()).toList(),
      weather: weather,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: syncStatus,
    );
  }

  /// Create model from domain entity
  factory DiaryEntryModel.fromEntity(DiaryEntry entity) {
    return DiaryEntryModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      content: entity.content,
      photoUrls: entity.photoUrls,
      tags: entity.tags.map((t) => TagModel.fromEntity(t)).toList(),
      weather: entity.weather,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      syncStatus: entity.syncStatus,
    );
  }
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
