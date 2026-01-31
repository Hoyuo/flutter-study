import 'package:core/core.dart';
import 'package:diary/domain/entities/entities.dart';

part 'diary_state.freezed.dart';

/// Diary Bloc의 상태
///
/// Freezed를 사용하여 불변 상태를 정의합니다.
@freezed
abstract class DiaryState with _$DiaryState {
  const factory DiaryState({
    /// 일기 목록
    @Default([]) List<DiaryEntry> entries,

    /// 현재 선택된 일기
    DiaryEntry? selectedEntry,

    /// 로딩 중 여부
    @Default(false) bool isLoading,

    /// 추가 로딩 중 여부 (페이지네이션)
    @Default(false) bool isLoadingMore,

    /// 마지막 페이지 도달 여부
    @Default(false) bool hasReachedEnd,

    /// 현재 페이지
    @Default(1) int currentPage,

    /// 검색 키워드
    String? searchKeyword,

    /// 필터링할 태그 ID
    String? filterTagId,

    /// 에러 발생 시 Failure 객체
    Failure? failure,
  }) = _DiaryState;

  /// 초기 상태
  factory DiaryState.initial() => const DiaryState();
}
