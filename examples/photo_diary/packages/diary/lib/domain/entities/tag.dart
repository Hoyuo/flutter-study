import 'package:core/core.dart';

part 'tag.freezed.dart';

/// Tag entity for categorizing diary entries
@freezed
abstract class Tag with _$Tag {
  const factory Tag({
    required String id,
    required String name,
    required String colorHex,
    required String userId,
  }) = _Tag;
}
