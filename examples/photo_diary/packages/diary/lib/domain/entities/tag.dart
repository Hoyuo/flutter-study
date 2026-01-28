import 'package:core/core.dart';

part 'tag.freezed.dart';
part 'tag.g.dart';

/// Tag entity for categorizing diary entries
@freezed
class Tag with _$Tag {
  const factory Tag({
    required String id,
    required String name,
    required String colorHex,
    required String userId,
  }) = _Tag;

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);
}
