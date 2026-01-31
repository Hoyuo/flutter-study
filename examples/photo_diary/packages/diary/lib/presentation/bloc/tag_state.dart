import 'package:core/core.dart';
import 'package:diary/domain/entities/entities.dart';

part 'tag_state.freezed.dart';

/// Tag Bloc의 상태
///
/// Freezed를 사용하여 불변 상태를 정의합니다.
@freezed
abstract class TagState with _$TagState {
  const factory TagState({
    /// 태그 목록
    @Default([]) List<Tag> tags,

    /// 현재 선택된 태그 ID
    String? selectedTagId,

    /// 로딩 중 여부
    @Default(false) bool isLoading,

    /// 에러 발생 시 Failure 객체
    Failure? failure,
  }) = _TagState;

  /// 초기 상태
  factory TagState.initial() => const TagState();
}
