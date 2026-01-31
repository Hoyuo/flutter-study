import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core/core.dart';
import '../../domain/entities/entities.dart';

part 'tag_model.freezed.dart';
part 'tag_model.g.dart';

/// Data model for tag with Firestore mapping
@freezed
abstract class TagModel with _$TagModel {
  const TagModel._();

  const factory TagModel({
    required String id,
    required String name,
    required String colorHex,
    required String userId,
  }) = _TagModel;

  /// Create model from JSON
  factory TagModel.fromJson(Map<String, dynamic> json) =>
      _$TagModelFromJson(json);

  /// Create model from Firestore document
  factory TagModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TagModel(
      id: doc.id,
      name: data['name'] as String,
      colorHex: data['colorHex'] as String,
      userId: data['userId'] as String,
    );
  }

  /// Convert model to Firestore document data
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'colorHex': colorHex,
      'userId': userId,
    };
  }

  /// Convert model to domain entity
  Tag toEntity() {
    return Tag(
      id: id,
      name: name,
      colorHex: colorHex,
      userId: userId,
    );
  }

  /// Create model from domain entity
  factory TagModel.fromEntity(Tag entity) {
    return TagModel(
      id: entity.id,
      name: entity.name,
      colorHex: entity.colorHex,
      userId: entity.userId,
    );
  }
}
