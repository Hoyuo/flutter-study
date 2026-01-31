import 'package:core/core.dart';
import 'package:diary/domain/entities/entities.dart';

part 'tag_event.freezed.dart';

/// Tag 관련 이벤트들
///
/// Freezed를 사용하여 sealed class로 정의된 이벤트들입니다.
@freezed
abstract class TagEvent with _$TagEvent {
  /// 태그 목록 로드 이벤트
  const factory TagEvent.loadTags() = LoadTags;

  /// 태그 생성 이벤트
  ///
  /// [tag] 생성할 태그 엔티티
  const factory TagEvent.createTag(Tag tag) = CreateTag;

  /// 태그 선택 이벤트
  ///
  /// [tagId] 선택할 태그 ID
  const factory TagEvent.selectTag(String tagId) = SelectTag;

  /// 태그 선택 해제 이벤트
  const factory TagEvent.deselectTag() = DeselectTag;
}
