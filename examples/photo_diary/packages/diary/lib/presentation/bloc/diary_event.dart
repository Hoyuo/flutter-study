import 'package:core/core.dart';
import 'package:diary/domain/entities/entities.dart';

part 'diary_event.freezed.dart';

/// Diary 관련 이벤트들
///
/// Freezed를 사용하여 sealed class로 정의된 이벤트들입니다.
@freezed
sealed class DiaryEvent with _$DiaryEvent {
  /// 일기 목록 로드 이벤트
  ///
  /// [startDate] 시작 날짜 (선택)
  /// [endDate] 종료 날짜 (선택)
  const factory DiaryEvent.loadEntries({
    DateTime? startDate,
    DateTime? endDate,
  }) = LoadDiaryEntries;

  /// 추가 일기 목록 로드 이벤트 (페이지네이션)
  const factory DiaryEvent.loadMoreEntries() = LoadMoreDiaryEntries;

  /// 특정 일기 로드 이벤트
  ///
  /// [id] 일기 ID
  const factory DiaryEvent.loadEntry(String id) = LoadDiaryEntry;

  /// 일기 생성 이벤트
  ///
  /// [entry] 생성할 일기 엔티티
  const factory DiaryEvent.createEntry(DiaryEntry entry) = CreateDiaryEntry;

  /// 일기 수정 이벤트
  ///
  /// [entry] 수정할 일기 엔티티
  const factory DiaryEvent.updateEntry(DiaryEntry entry) = UpdateDiaryEntry;

  /// 일기 삭제 이벤트
  ///
  /// [id] 삭제할 일기 ID
  const factory DiaryEvent.deleteEntry(String id) = DeleteDiaryEntry;

  /// 키워드로 검색 이벤트
  ///
  /// [keyword] 검색 키워드
  const factory DiaryEvent.searchByKeyword(String keyword) = SearchByKeyword;

  /// 태그로 필터링 이벤트
  ///
  /// [tagId] 필터링할 태그 ID
  const factory DiaryEvent.filterByTag(String tagId) = FilterByTag;

  /// 필터 초기화 이벤트
  const factory DiaryEvent.clearFilters() = ClearFilters;
}
