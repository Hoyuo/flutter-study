import 'package:flutter/material.dart';
import '../../domain/entities/diary_entry.dart';
import 'weather_info_card.dart';

/// 일기 목록에서 사용하는 카드 위젯
///
/// 대표 사진, 제목, 날짜, 날씨, 태그를 표시합니다.
class DiaryCard extends StatelessWidget {
  /// 일기 엔트리
  final DiaryEntry entry;

  /// 카드 클릭 핸들러
  final VoidCallback? onTap;

  const DiaryCard({
    super.key,
    required this.entry,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 날씨 정보 텍스트 생성
    final weatherText = entry.weather != null
        ? ', 날씨: ${_getWeatherDescription(entry.weather!)}'
        : '';

    // 태그 정보 텍스트 생성
    final tagsText = entry.tags.isNotEmpty
        ? ', 태그: ${entry.tags.take(3).map((tag) => tag.name).join(', ')}'
        : '';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          label:
              '일기: ${entry.title}, ${_formatDate(entry.createdAt)}$weatherText$tagsText',
          button: true,
          hint: '탭하여 일기 상세 내용 보기',
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 대표 사진 썸네일
              if (entry.photoUrls.isNotEmpty)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Semantics(
                    image: true,
                    label: '일기 대표 사진',
                    child: Image.network(
                      entry.photoUrls.first,
                      fit: BoxFit.cover,
                      semanticLabel: '일기 대표 사진',
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colorScheme.surfaceVariant,
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              color: colorScheme.onSurfaceVariant,
                              size: 48,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              else
                // 사진이 없는 경우 플레이스홀더
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Semantics(
                    excludeSemantics: true,
                    child: Container(
                      color: colorScheme.surfaceVariant,
                      child: Center(
                        child: Icon(
                          Icons.photo_library_outlined,
                          color: colorScheme.onSurfaceVariant,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),

              // 내용 영역
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 & 날씨
                    Row(
                      children: [
                        // 제목
                        Expanded(
                          child: Text(
                            entry.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // 날씨 아이콘
                        if (entry.weather != null) ...[
                          const SizedBox(width: 8),
                          WeatherInfoCard(
                            weather: entry.weather!,
                            compact: true,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 날짜
                    Text(
                      _formatDate(entry.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                    // 태그 (최대 3개)
                    if (entry.tags.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: entry.tags
                            .take(3)
                            .map(
                              (tag) => Chip(
                                label: Text(
                                  tag.name,
                                  style: theme.textTheme.bodySmall,
                                ),
                                backgroundColor: _parseColor(tag.colorHex),
                                visualDensity: VisualDensity.compact,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 날짜를 포맷팅
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) {
      return '오늘 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (entryDate == yesterday) {
      return '어제 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.year}년 ${date.month}월 ${date.day}일';
    }
  }

  /// Hex 컬러 문자열을 Color로 파싱
  Color _parseColor(String hexColor) {
    final hexCode = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexCode', radix: 16));
  }

  /// 날씨 정보를 접근성용 텍스트로 변환
  String _getWeatherDescription(dynamic weather) {
    // weather 객체의 구조에 따라 적절한 텍스트 반환
    // 예: "맑음" 또는 "흐림, 온도 25도"
    return weather.toString();
  }
}
