import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart' hide State;
import '../bloc/bloc.dart';
import '../widgets/widgets.dart';

/// 일기 목록 홈 화면
///
/// 무한 스크롤, Pull-to-refresh, 검색 기능을 제공합니다.
class DiaryListPage extends StatefulWidget {
  const DiaryListPage({super.key});

  @override
  State<DiaryListPage> createState() => _DiaryListPageState();
}

class _DiaryListPageState extends State<DiaryListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 초기 데이터 로드
    context.read<DiaryBloc>().add(const DiaryEvent.loadEntries());

    // 무한 스크롤 리스너 등록
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 스크롤 이벤트 처리
  void _onScroll() {
    if (_isBottom) {
      context.read<DiaryBloc>().add(const DiaryEvent.loadMoreEntries());
    }
  }

  /// 스크롤이 하단에 도달했는지 확인
  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: BlocUiEffectListener<DiaryBloc, DiaryState, DiaryUiEffect>(
        listener: _handleUiEffect,
        child: _buildBody(context),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  /// AppBar 빌드
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Photo Diary'),
      actions: [
        // 검색 버튼
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: '검색',
          onPressed: () {
            // TODO: 검색 페이지로 이동
            // context.push('/search');
          },
        ),
      ],
    );
  }

  /// Body 빌드
  Widget _buildBody(BuildContext context) {
    return BlocBuilder<DiaryBloc, DiaryState>(
      builder: (context, state) {
        // 로딩 중 (초기 로드)
        if (state.isLoading && state.entries.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // 에러 발생
        if (state.failure != null && state.entries.isEmpty) {
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
                  '데이터를 불러오는데 실패했습니다',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    context
                        .read<DiaryBloc>()
                        .add(const DiaryEvent.loadEntries());
                  },
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        // 빈 상태
        if (state.entries.isEmpty) {
          return EmptyState(
            icon: Icons.book_outlined,
            title: '아직 작성한 일기가 없습니다',
            message: '첫 번째 일기를 작성해보세요!',
            buttonText: '일기 작성',
            onButtonPressed: () {
              // TODO: 일기 작성 페이지로 이동
              // context.push('/diary/create');
            },
          );
        }

        // 일기 목록
        return RefreshIndicator(
          onRefresh: () async {
            context.read<DiaryBloc>().add(const DiaryEvent.loadEntries());
            // 로딩이 완료될 때까지 대기
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              // 스크롤 이벤트 처리
              if (notification is ScrollEndNotification &&
                  _scrollController.position.extentAfter < 200) {
                context
                    .read<DiaryBloc>()
                    .add(const DiaryEvent.loadMoreEntries());
              }
              return false;
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.entries.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                // 로딩 인디케이터 (페이지네이션)
                if (index == state.entries.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                // 일기 카드
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
            ),
          ),
        );
      },
    );
  }

  /// FAB 빌드
  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        // TODO: 일기 작성 페이지로 이동
        // context.push('/diary/create');
      },
      icon: const Icon(Icons.add),
      label: const Text('일기 작성'),
    );
  }

  /// UI 이펙트 처리
  void _handleUiEffect(BuildContext context, DiaryUiEffect effect) {
    effect.when(
      showError: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
      showSuccess: (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      },
      navigateToDetail: (entryId) {
        // TODO: 상세 페이지로 이동
        // context.push('/diary/$entryId');
      },
      navigateBack: () {
        Navigator.of(context).pop();
      },
      confirmDelete: (entryId) {
        // 삭제 확인 다이얼로그는 상세 페이지에서 처리
      },
    );
  }
}
