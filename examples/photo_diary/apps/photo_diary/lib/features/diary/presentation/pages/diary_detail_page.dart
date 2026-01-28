import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:diary/diary.dart';
import 'package:photo_diary/core/di/injection.dart';

/// 다이어리 상세 페이지
///
/// 특정 다이어리 항목의 전체 내용을 표시하고,
/// 수정 및 삭제 기능을 제공합니다.
class DiaryDetailPage extends StatefulWidget {
  const DiaryDetailPage({super.key, required this.entryId});

  final String entryId;

  @override
  State<DiaryDetailPage> createState() => _DiaryDetailPageState();
}

class _DiaryDetailPageState extends State<DiaryDetailPage> {
  late final DiaryBloc _diaryBloc;

  @override
  void initState() {
    super.initState();
    _diaryBloc = getIt<DiaryBloc>()..add(DiaryEvent.loadEntry(widget.entryId));
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
          title: const Text('일기'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/diary/${widget.entryId}/edit'),
              tooltip: '수정',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _handleDelete,
              tooltip: '삭제',
            ),
          ],
        ),
        body: BlocConsumer<DiaryBloc, DiaryState>(
          listener: (context, state) {
            // 에러 처리
            if (state.failure != null) {
              final message = state.failure!.when(
                network: (msg, _) => msg,
                server: (msg, _, __) => msg,
                auth: (msg, _) => msg,
                cache: (msg, _) => msg,
                unknown: (msg, _) => msg,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          builder: (context, state) {
            // 로딩 중
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // 일기 항목 로드됨
            if (state.selectedEntry != null) {
              final entry = state.selectedEntry!;
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 사진 갤러리
                    if (entry.photoUrls.isNotEmpty)
                      SizedBox(
                        height: 300,
                        child: PageView.builder(
                          itemCount: entry.photoUrls.length,
                          itemBuilder: (context, index) {
                            return Image.network(
                              entry.photoUrls[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 날짜
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(entry.createdAt),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // 내용
                          Text(
                            entry.content,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),

                          // 날씨와 위치 정보는 향후 구현 예정
                          // TODO: WeatherInfo 객체와 위치 정보 표시 구현
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            // 에러 상태
            if (state.failure != null) {
              final message = state.failure!.when(
                network: (msg, _) => msg,
                server: (msg, _, __) => msg,
                auth: (msg, _) => msg,
                cache: (msg, _) => msg,
                unknown: (msg, _) => msg,
              );
              return _buildErrorState(context, message);
            }

            // 기본 상태 (항목이 없음)
            return const Center(child: Text('일기를 찾을 수 없습니다'));
          },
        ),
      ),
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
            onPressed: () => context.go('/diary'),
            child: const Text('목록으로'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];
    return '${date.year}년 ${date.month}월 ${date.day}일 $weekday요일';
  }

  void _handleDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일기 삭제'),
        content: const Text('이 일기를 삭제하시겠습니까?\n삭제된 일기는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _diaryBloc.add(DiaryEvent.deleteEntry(widget.entryId));
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
