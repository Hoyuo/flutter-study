import 'package:core/core.dart';
import 'package:diary/domain/usecases/usecases.dart';
import 'package:diary/presentation/bloc/diary_event.dart';
import 'package:diary/presentation/bloc/diary_state.dart';
import 'package:diary/presentation/bloc/diary_ui_effect.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Diary 기능을 관리하는 Bloc
///
/// BlocUiEffectMixin을 사용하여 일회성 UI 이벤트를 처리합니다.
/// 페이지네이션, 검색, 필터링 기능을 지원합니다.
class DiaryBloc extends Bloc<DiaryEvent, DiaryState>
    with BlocUiEffectMixin<DiaryUiEffect, DiaryState> {
  DiaryBloc({
    required GetDiariesUseCase getDiariesUseCase,
    required GetDiaryByIdUseCase getDiaryByIdUseCase,
    required CreateDiaryUseCase createDiaryUseCase,
    required UpdateDiaryUseCase updateDiaryUseCase,
    required DeleteDiaryUseCase deleteDiaryUseCase,
    required SearchDiariesUseCase searchDiariesUseCase,
  })  : _getDiariesUseCase = getDiariesUseCase,
        _getDiaryByIdUseCase = getDiaryByIdUseCase,
        _createDiaryUseCase = createDiaryUseCase,
        _updateDiaryUseCase = updateDiaryUseCase,
        _deleteDiaryUseCase = deleteDiaryUseCase,
        _searchDiariesUseCase = searchDiariesUseCase,
        super(DiaryState.initial()) {
    // 이벤트 핸들러 등록
    on<LoadDiaryEntries>(_onLoadEntries);
    on<LoadMoreDiaryEntries>(_onLoadMoreEntries);
    on<LoadDiaryEntry>(_onLoadEntry);
    on<CreateDiaryEntry>(_onCreateEntry);
    on<UpdateDiaryEntry>(_onUpdateEntry);
    on<DeleteDiaryEntry>(_onDeleteEntry);
    on<SearchByKeyword>(_onSearchByKeyword);
    on<FilterByTag>(_onFilterByTag);
    on<ClearFilters>(_onClearFilters);
  }

  /// 페이지당 아이템 수
  static const int _pageSize = 20;

  final GetDiariesUseCase _getDiariesUseCase;
  final GetDiaryByIdUseCase _getDiaryByIdUseCase;
  final CreateDiaryUseCase _createDiaryUseCase;
  final UpdateDiaryUseCase _updateDiaryUseCase;
  final DeleteDiaryUseCase _deleteDiaryUseCase;
  final SearchDiariesUseCase _searchDiariesUseCase;

  /// 마지막 엔트리 ID (페이지네이션용)
  String? _lastEntryId;

  /// 일기 목록 로드 핸들러
  Future<void> _onLoadEntries(
    LoadDiaryEntries event,
    Emitter<DiaryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, failure: null));

    // 검색어가 있으면 검색, 없으면 일반 로드
    if (state.searchKeyword != null && state.searchKeyword!.isNotEmpty) {
      await _searchEntries(emit);
    } else {
      await _loadEntries(emit, isInitial: true);
    }

    emit(state.copyWith(isLoading: false));
  }

  /// 추가 일기 로드 핸들러 (페이지네이션)
  Future<void> _onLoadMoreEntries(
    LoadMoreDiaryEntries event,
    Emitter<DiaryState> emit,
  ) async {
    // 이미 로딩 중이거나 마지막 페이지에 도달했으면 무시
    if (state.isLoadingMore || state.hasReachedEnd) return;

    emit(state.copyWith(isLoadingMore: true));

    // 검색어가 있으면 검색 결과 추가 로드는 지원하지 않음
    if (state.searchKeyword == null || state.searchKeyword!.isEmpty) {
      await _loadEntries(emit, isInitial: false);
    }

    emit(state.copyWith(isLoadingMore: false));
  }

  /// 일기 목록 로드 내부 메서드
  Future<void> _loadEntries(
    Emitter<DiaryState> emit, {
    required bool isInitial,
  }) async {
    final result = await _getDiariesUseCase(
      GetDiariesParams(
        lastEntryId: isInitial ? null : _lastEntryId,
      ),
    );

    result.fold(
      // 실패 시
      (failure) {
        emit(state.copyWith(failure: failure));
        emitUiEffect(DiaryUiEffect.showError(_getFailureMessage(failure)));
      },
      // 성공 시
      (entries) {
        // 마지막 엔트리 ID 저장
        if (entries.isNotEmpty) {
          _lastEntryId = entries.last.id;
        }

        // 페이지 끝 여부 확인
        final hasReachedEnd = entries.length < _pageSize;

        if (isInitial) {
          // 초기 로드
          emit(
            state.copyWith(
              entries: entries,
              hasReachedEnd: hasReachedEnd,
              currentPage: 1,
            ),
          );
        } else {
          // 추가 로드
          emit(
            state.copyWith(
              entries: [...state.entries, ...entries],
              hasReachedEnd: hasReachedEnd,
              currentPage: state.currentPage + 1,
            ),
          );
        }
      },
    );
  }

  /// 특정 일기 로드 핸들러
  Future<void> _onLoadEntry(
    LoadDiaryEntry event,
    Emitter<DiaryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, failure: null));

    final result = await _getDiaryByIdUseCase(event.id);

    result.fold(
      // 실패 시
      (failure) {
        emit(state.copyWith(failure: failure, isLoading: false));
        emitUiEffect(DiaryUiEffect.showError(_getFailureMessage(failure)));
      },
      // 성공 시
      (entry) {
        emit(
          state.copyWith(
            selectedEntry: entry,
            isLoading: false,
          ),
        );
      },
    );
  }

  /// 일기 생성 핸들러
  Future<void> _onCreateEntry(
    CreateDiaryEntry event,
    Emitter<DiaryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, failure: null));

    final result = await _createDiaryUseCase(event.entry);

    result.fold(
      // 실패 시
      (failure) {
        emit(state.copyWith(failure: failure, isLoading: false));
        emitUiEffect(DiaryUiEffect.showError(_getFailureMessage(failure)));
      },
      // 성공 시
      (createdEntry) {
        // 목록에 추가 (최신순이므로 맨 앞에 추가)
        emit(
          state.copyWith(
            entries: [createdEntry, ...state.entries],
            isLoading: false,
          ),
        );
        emitUiEffect(const DiaryUiEffect.showSuccess('일기가 생성되었습니다'));
        emitUiEffect(DiaryUiEffect.navigateToDetail(createdEntry.id));
      },
    );
  }

  /// 일기 수정 핸들러
  Future<void> _onUpdateEntry(
    UpdateDiaryEntry event,
    Emitter<DiaryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, failure: null));

    final result = await _updateDiaryUseCase(event.entry);

    result.fold(
      // 실패 시
      (failure) {
        emit(state.copyWith(failure: failure, isLoading: false));
        emitUiEffect(DiaryUiEffect.showError(_getFailureMessage(failure)));
      },
      // 성공 시
      (updatedEntry) {
        // 목록에서 해당 엔트리 업데이트
        final updatedEntries = state.entries.map((entry) {
          return entry.id == updatedEntry.id ? updatedEntry : entry;
        }).toList();

        emit(
          state.copyWith(
            entries: updatedEntries,
            selectedEntry: state.selectedEntry?.id == updatedEntry.id
                ? updatedEntry
                : null,
            isLoading: false,
          ),
        );
        emitUiEffect(const DiaryUiEffect.showSuccess('일기가 수정되었습니다'));
        emitUiEffect(const DiaryUiEffect.navigateBack());
      },
    );
  }

  /// 일기 삭제 핸들러
  Future<void> _onDeleteEntry(
    DeleteDiaryEntry event,
    Emitter<DiaryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, failure: null));

    final result = await _deleteDiaryUseCase(event.id);

    result.fold(
      // 실패 시
      (failure) {
        emit(state.copyWith(failure: failure, isLoading: false));
        emitUiEffect(DiaryUiEffect.showError(_getFailureMessage(failure)));
      },
      // 성공 시
      (_) {
        // 목록에서 제거
        final updatedEntries =
            state.entries.where((entry) => entry.id != event.id).toList();

        emit(
          state.copyWith(
            entries: updatedEntries,
            selectedEntry: state.selectedEntry?.id == event.id
                ? null
                : state.selectedEntry,
            isLoading: false,
          ),
        );
        emitUiEffect(const DiaryUiEffect.showSuccess('일기가 삭제되었습니다'));
        emitUiEffect(const DiaryUiEffect.navigateBack());
      },
    );
  }

  /// 키워드 검색 핸들러
  Future<void> _onSearchByKeyword(
    SearchByKeyword event,
    Emitter<DiaryState> emit,
  ) async {
    emit(
      state.copyWith(
        searchKeyword: event.keyword,
        isLoading: true,
        failure: null,
      ),
    );

    await _searchEntries(emit);

    emit(state.copyWith(isLoading: false));
  }

  /// 검색 실행 내부 메서드
  Future<void> _searchEntries(Emitter<DiaryState> emit) async {
    if (state.searchKeyword == null || state.searchKeyword!.isEmpty) {
      return;
    }

    final result = await _searchDiariesUseCase(
      SearchDiariesParams(
        query: state.searchKeyword!,
      ),
    );

    result.fold(
      // 실패 시
      (failure) {
        emit(state.copyWith(failure: failure));
        emitUiEffect(DiaryUiEffect.showError(_getFailureMessage(failure)));
      },
      // 성공 시
      (entries) {
        emit(
          state.copyWith(
            entries: entries,
            hasReachedEnd: true, // 검색 결과는 페이지네이션 미지원
          ),
        );
      },
    );
  }

  /// 태그로 필터링 핸들러
  Future<void> _onFilterByTag(
    FilterByTag event,
    Emitter<DiaryState> emit,
  ) async {
    emit(
      state.copyWith(
        filterTagId: event.tagId,
        isLoading: true,
        failure: null,
      ),
    );

    // TODO: 태그 필터링 로직 구현 (repository에 메서드 추가 필요)
    // 현재는 클라이언트 사이드 필터링으로 구현
    final allEntries = state.entries;
    final filteredEntries = allEntries.where((entry) {
      return entry.tags.any((tag) => tag.id == event.tagId);
    }).toList();

    emit(
      state.copyWith(
        entries: filteredEntries,
        isLoading: false,
      ),
    );
  }

  /// 필터 초기화 핸들러
  Future<void> _onClearFilters(
    ClearFilters event,
    Emitter<DiaryState> emit,
  ) async {
    emit(
      state.copyWith(
        searchKeyword: null,
        filterTagId: null,
      ),
    );

    // 필터 초기화 후 재로드
    add(const DiaryEvent.loadEntries());
  }

  /// Failure 객체를 사용자 친화적인 메시지로 변환
  String _getFailureMessage(Failure failure) {
    return failure.when(
      network: (message, _) => '네트워크 오류: $message',
      server: (message, _, __) => '서버 오류: $message',
      auth: (message, _) => '인증 오류: $message',
      cache: (message, _) => '캐시 오류: $message',
      unknown: (message, _) => '알 수 없는 오류: $message',
    );
  }
}
