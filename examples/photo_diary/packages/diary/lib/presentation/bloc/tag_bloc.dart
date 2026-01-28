import 'package:diary/domain/usecases/usecases.dart';
import 'package:diary/presentation/bloc/tag_event.dart';
import 'package:diary/presentation/bloc/tag_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Tag 기능을 관리하는 Bloc
///
/// 태그의 CRUD를 처리합니다.
class TagBloc extends Bloc<TagEvent, TagState> {
  TagBloc({
    required GetTagsUseCase getTagsUseCase,
    required CreateTagUseCase createTagUseCase,
  })  : _getTagsUseCase = getTagsUseCase,
        _createTagUseCase = createTagUseCase,
        super(TagState.initial()) {
    // 이벤트 핸들러 등록
    on<LoadTags>(_onLoadTags);
    on<CreateTag>(_onCreateTag);
    on<SelectTag>(_onSelectTag);
    on<DeselectTag>(_onDeselectTag);
  }

  final GetTagsUseCase _getTagsUseCase;
  final CreateTagUseCase _createTagUseCase;

  /// 태그 목록 로드 핸들러
  Future<void> _onLoadTags(
    LoadTags event,
    Emitter<TagState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, failure: null));

    final result = await _getTagsUseCase();

    result.fold(
      // 실패 시
      (failure) {
        emit(
          state.copyWith(
            failure: failure,
            isLoading: false,
          ),
        );
      },
      // 성공 시
      (tags) {
        emit(
          state.copyWith(
            tags: tags,
            isLoading: false,
          ),
        );
      },
    );
  }

  /// 태그 생성 핸들러
  Future<void> _onCreateTag(
    CreateTag event,
    Emitter<TagState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, failure: null));

    final result = await _createTagUseCase(event.tag);

    result.fold(
      // 실패 시
      (failure) {
        emit(
          state.copyWith(
            failure: failure,
            isLoading: false,
          ),
        );
      },
      // 성공 시
      (createdTag) {
        // 목록에 추가
        emit(
          state.copyWith(
            tags: [...state.tags, createdTag],
            isLoading: false,
          ),
        );
      },
    );
  }

  /// 태그 선택 핸들러
  void _onSelectTag(
    SelectTag event,
    Emitter<TagState> emit,
  ) {
    emit(state.copyWith(selectedTagId: event.tagId));
  }

  /// 태그 선택 해제 핸들러
  void _onDeselectTag(
    DeselectTag event,
    Emitter<TagState> emit,
  ) {
    emit(state.copyWith(selectedTagId: null));
  }
}
