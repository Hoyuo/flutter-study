import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart' hide State;
import '../../domain/entities/entities.dart';
import '../bloc/bloc.dart';
import '../widgets/widgets.dart';

/// 일기 검색 화면
///
/// 검색어 입력 (debounce), 검색 결과 표시, 태그 필터링 기능을 제공합니다.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  String? _selectedTagId;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// 검색어 변경 처리 (debounce)
  void _onSearchChanged(String query) {
    // 기존 타이머 취소
    _debounce?.cancel();

    // 500ms 후 검색 실행
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        context.read<DiaryBloc>().add(
              DiaryEvent.searchByKeyword(query.trim()),
            );
      } else {
        // 검색어가 비어있으면 필터 초기화
        context.read<DiaryBloc>().add(const DiaryEvent.clearFilters());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // 태그 필터 칩
          _buildTagFilter(context),

          // 검색 결과
          Expanded(
            child: BlocUiEffectListener<DiaryBloc, DiaryState, DiaryUiEffect>(
              listener: _handleUiEffect,
              child: _buildSearchResults(context),
            ),
          ),
        ],
      ),
    );
  }

  /// AppBar 빌드
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: '일기 검색...',
          border: InputBorder.none,
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        onChanged: _onSearchChanged,
      ),
      actions: [
        // 검색어 지우기 버튼
        if (_searchController.text.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              context.read<DiaryBloc>().add(const DiaryEvent.clearFilters());
            },
          ),
      ],
    );
  }

  /// 태그 필터 빌드
  Widget _buildTagFilter(BuildContext context) {
    // TODO: TagBloc에서 실제 태그 목록 가져오기
    final tags = _getMockTags();

    if (tags.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // 전체 보기 칩
            FilterChip(
              label: const Text('전체'),
              selected: _selectedTagId == null,
              onSelected: (_) {
                setState(() {
                  _selectedTagId = null;
                });
                context.read<DiaryBloc>().add(const DiaryEvent.clearFilters());
              },
            ),
            const SizedBox(width: 8),

            // 태그 칩들
            ...tags.map((tag) {
              final isSelected = _selectedTagId == tag.id;
              final tagColor = ColorUtils.parseHex(tag.colorHex);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(tag.name),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedTagId = isSelected ? null : tag.id;
                    });

                    if (_selectedTagId != null) {
                      context
                          .read<DiaryBloc>()
                          .add(DiaryEvent.filterByTag(_selectedTagId!));
                    } else {
                      context
                          .read<DiaryBloc>()
                          .add(const DiaryEvent.clearFilters());
                    }
                  },
                  backgroundColor: tagColor.withValues(alpha: 0.1),
                  selectedColor: tagColor.withValues(alpha: 0.3),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 검색 결과 빌드
  Widget _buildSearchResults(BuildContext context) {
    return BlocBuilder<DiaryBloc, DiaryState>(
      buildWhen: (prev, curr) => prev.entries != curr.entries || prev.isLoading != curr.isLoading || prev.failure != curr.failure || prev.searchKeyword != curr.searchKeyword,
      builder: (context, state) {
        // 로딩 중
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // 에러 발생
        if (state.failure != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  '검색 중 오류가 발생했습니다',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        // 검색어가 없는 경우
        if (state.searchKeyword == null || state.searchKeyword!.isEmpty) {
          return EmptyState(
            icon: Icons.search,
            title: '검색어를 입력하세요',
            message: '제목이나 내용으로 일기를 검색할 수 있습니다',
          );
        }

        // 검색 결과가 없는 경우
        if (state.entries.isEmpty) {
          return EmptyState(
            icon: Icons.search_off,
            title: '검색 결과가 없습니다',
            message: '다른 검색어로 다시 시도해보세요',
          );
        }

        // 검색 결과 목록
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.entries.length,
          itemBuilder: (context, index) {
            final entry = state.entries[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DiaryCard(
                entry: entry,
                onTap: () {
                  // TODO: 상세 페이지로 이동
                  // context.push('/diary/${entry.id}');
                },
              ),
            );
          },
        );
      },
    );
  }

  /// UI 이펙트 처리
  void _handleUiEffect(BuildContext context, DiaryUiEffect effect) {
    switch (effect) {
      case DiaryShowError(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      case DiaryShowSuccess(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      case DiaryNavigateToDetail():
        // TODO: 상세 페이지로 이동
        // context.push('/diary/$entryId');
        break;
      case DiaryNavigateBack():
        Navigator.of(context).pop();
      case DiaryConfirmDelete():
        // 이 페이지에서는 사용하지 않음
        break;
    }
  }

  /// 태그 목록 가져오기
  ///
  /// TODO: TagBloc 구현 후 실제 태그 목록으로 대체
  /// 현재는 빈 리스트를 반환하여 태그 필터 UI를 숨김
  List<Tag> _getMockTags() {
    return [];
  }
}
