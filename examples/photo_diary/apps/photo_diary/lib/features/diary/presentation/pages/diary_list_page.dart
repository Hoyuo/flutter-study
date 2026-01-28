import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:diary/diary.dart';
import 'package:auth/auth.dart';
import 'package:photo_diary/core/di/injection.dart';

/// 다이어리 목록 페이지
///
/// 사용자의 모든 다이어리 항목을 표시하고,
/// 새로운 항목을 추가할 수 있습니다.
class DiaryListPage extends StatefulWidget {
  const DiaryListPage({super.key});

  @override
  State<DiaryListPage> createState() => _DiaryListPageState();
}

class _DiaryListPageState extends State<DiaryListPage> {
  late final DiaryBloc _diaryBloc;

  @override
  void initState() {
    super.initState();
    // DiaryBloc을 DI 컨테이너에서 가져와 사용
    _diaryBloc = getIt<DiaryBloc>()..add(const DiaryEvent.loadEntries());
  }

  @override
  void dispose() {
    _diaryBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _diaryBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Photo Diary'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => context.push('/search'),
              tooltip: '검색',
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => context.push('/settings'),
              tooltip: '설정',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') {
                  _handleLogout();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout),
                      SizedBox(width: 8),
                      Text('로그아웃'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: BlocBuilder<DiaryBloc, DiaryState>(
          builder: (context, state) {
            // 로딩 중
            if (state.isLoading && state.entries.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // 에러 상태
            if (state.failure != null && state.entries.isEmpty) {
              final message = state.failure!.when(
                network: (msg, _) => msg,
                server: (msg, _, __) => msg,
                auth: (msg, _) => msg,
                cache: (msg, _) => msg,
                unknown: (msg, _) => msg,
              );
              return _buildErrorState(context, message);
            }

            // 빈 상태
            if (state.entries.isEmpty) {
              return _buildEmptyState(context);
            }

            // 목록 표시
            return _buildDiaryList(context, state.entries);
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/diary/new'),
          icon: const Icon(Icons.add),
          label: const Text('새 일기'),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text('아직 일기가 없습니다', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            '새 일기 버튼을 눌러 첫 일기를 작성해보세요',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryList(BuildContext context, List<DiaryEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () => context.push('/diary/${entry.id}'),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜
                  Text(
                    _formatDate(entry.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 제목 (첫 줄)
                  Text(
                    entry.content.split('\n').first,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // 내용 미리보기
                  Text(
                    entry.content,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // 사진이 있는 경우
                  if (entry.photoUrls.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.photo,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.secondary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${entry.photoUrls.length}장의 사진',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary.withValues(alpha: 0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text('오류가 발생했습니다', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _diaryBloc.add(const DiaryEvent.loadEntries());
            },
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const AuthEvent.signOutRequested());
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}
