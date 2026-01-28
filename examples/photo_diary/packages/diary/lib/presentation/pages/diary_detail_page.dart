import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:core/core.dart' hide State;
import '../../domain/entities/entities.dart';
import '../bloc/bloc.dart';
import '../widgets/widgets.dart';

/// 일기 상세 화면
///
/// 일기의 전체 내용, 사진, 태그, 날씨 정보를 표시합니다.
class DiaryDetailPage extends StatefulWidget {
  /// 일기 ID
  final String entryId;

  const DiaryDetailPage({
    super.key,
    required this.entryId,
  });

  @override
  State<DiaryDetailPage> createState() => _DiaryDetailPageState();
}

class _DiaryDetailPageState extends State<DiaryDetailPage> {
  final _pageController = PageController();
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    // 일기 상세 로드
    context.read<DiaryBloc>().add(DiaryEvent.loadEntry(widget.entryId));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocUiEffectListener<DiaryBloc, DiaryState, DiaryUiEffect>(
        listener: _handleUiEffect,
        child: _buildBody(context),
      ),
    );
  }

  /// Body 빌드
  Widget _buildBody(BuildContext context) {
    return BlocBuilder<DiaryBloc, DiaryState>(
      builder: (context, state) {
        // 로딩 중
        if (state.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // 에러 발생
        if (state.failure != null || state.selectedEntry == null) {
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
                  '일기를 불러올 수 없습니다',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('돌아가기'),
                ),
              ],
            ),
          );
        }

        final entry = state.selectedEntry!;
        return _buildContent(context, entry);
      },
    );
  }

  /// 콘텐츠 빌드
  Widget _buildContent(BuildContext context, DiaryEntry entry) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CustomScrollView(
      slivers: [
        // AppBar
        SliverAppBar(
          expandedHeight: entry.photoUrls.isNotEmpty ? 300 : 100,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              entry.title,
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            background: entry.photoUrls.isNotEmpty
                ? _buildPhotoSlider(context, entry.photoUrls)
                : Container(
                    color: colorScheme.primaryContainer,
                    child: Center(
                      child: Icon(
                        Icons.photo_library_outlined,
                        size: 64,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
          ),
          actions: [
            // 수정 버튼
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: '수정',
              onPressed: () {
                // TODO: 수정 페이지로 이동
                // context.push('/diary/${entry.id}/edit');
              },
            ),
            // 삭제 버튼
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: '삭제',
              onPressed: () => _showDeleteDialog(context, entry.id),
            ),
          ],
        ),

        // 콘텐츠
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 날짜 및 날씨
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(entry.createdAt),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    if (entry.weather != null)
                      WeatherInfoCard(
                        weather: entry.weather!,
                        compact: true,
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // 내용
                Text(
                  entry.content,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),

                // 태그
                if (entry.tags.isNotEmpty) ...[
                  Text(
                    '태그',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: entry.tags
                        .map(
                          (tag) => Chip(
                            label: Text(tag.name),
                            backgroundColor: _parseColor(tag.colorHex),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // 날씨 상세 정보
                if (entry.weather != null) ...[
                  WeatherInfoCard(weather: entry.weather!),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 사진 슬라이더 빌드
  Widget _buildPhotoSlider(BuildContext context, List<String> photoUrls) {
    return Stack(
      children: [
        // 사진 슬라이더
        PageView.builder(
          controller: _pageController,
          itemCount: photoUrls.length,
          onPageChanged: (index) {
            setState(() {
              _currentPhotoIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return Image.network(
              photoUrls[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            );
          },
        ),

        // 페이지 인디케이터
        if (photoUrls.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${_currentPhotoIndex + 1} / ${photoUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 삭제 확인 다이얼로그 표시
  void _showDeleteDialog(BuildContext context, String entryId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일기 삭제'),
        content: const Text('정말로 이 일기를 삭제하시겠습니까?\n삭제된 일기는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<DiaryBloc>().add(DiaryEvent.deleteEntry(entryId));
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
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
        // 이미 상세 페이지에 있음
      },
      navigateBack: () {
        Navigator.of(context).pop();
      },
      confirmDelete: (entryId) {
        _showDeleteDialog(context, entryId);
      },
    );
  }

  /// 날짜 포맷팅
  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일 '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Hex 컬러 문자열을 Color로 파싱
  Color _parseColor(String hexColor) {
    final hexCode = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }
}
