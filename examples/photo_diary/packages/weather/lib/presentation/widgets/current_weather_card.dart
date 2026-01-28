import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/entities.dart';
import '../bloc/bloc.dart';
import 'weather_icon.dart';

/// 현재 날씨 정보를 표시하는 카드 위젯
class CurrentWeatherCard extends StatelessWidget {
  /// 새로고침 버튼 표시 여부
  final bool showRefreshButton;

  /// 새로고침 콜백
  final VoidCallback? onRefresh;

  const CurrentWeatherCard({
    super.key,
    this.showRefreshButton = true,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeatherBloc, WeatherState>(
      builder: (context, state) {
        if (state.isLoading) {
          return _buildLoadingCard(context);
        }

        if (state.failure != null) {
          return _buildErrorCard(context, state.failure!);
        }

        if (state.weather == null) {
          return _buildEmptyCard(context);
        }

        return _buildWeatherCard(context, state.weather!, state.lastUpdated);
      },
    );
  }

  /// 로딩 중 카드
  Widget _buildLoadingCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 로딩 애니메이션
            SizedBox(
              height: 80,
              child: Center(
                child: CircularProgressIndicator(
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '날씨 정보를 불러오는 중...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 에러 카드
  Widget _buildErrorCard(BuildContext context, dynamic failure) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              '날씨 정보를 불러올 수 없습니다',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getErrorMessage(failure),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (showRefreshButton) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 빈 상태 카드
  Widget _buildEmptyCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              '날씨 정보 없음',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 날씨 정보 카드
  Widget _buildWeatherCard(
    BuildContext context,
    Weather weather,
    DateTime? lastUpdated,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 도시명 + 새로고침 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weather.cityName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (lastUpdated != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _formatLastUpdated(lastUpdated),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showRefreshButton)
                  IconButton(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh),
                    tooltip: '새로고침',
                  ),
              ],
            ),
            const Divider(height: 24),
            // 중앙: 날씨 아이콘 + 온도
            Row(
              children: [
                // 날씨 아이콘
                WeatherIcon(
                  iconCode: weather.iconCode,
                  size: 80,
                  color: WeatherIcon.getWeatherColor(
                    weather.iconCode,
                    context,
                  ),
                ),
                const SizedBox(width: 16),
                // 온도 및 설명
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 온도
                      Text(
                        '${weather.temperature.toStringAsFixed(1)}°C',
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 날씨 상태
                      Text(
                        weather.description,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // 하단: 습도 정보
            Row(
              children: [
                Icon(
                  Icons.water_drop,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '습도: ${weather.humidity}%',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 에러 메시지 포맷팅
  String _getErrorMessage(dynamic failure) {
    // Failure 타입에 따라 적절한 메시지 반환
    if (failure.toString().contains('Network')) {
      return '네트워크 연결을 확인해주세요';
    }
    if (failure.toString().contains('Server')) {
      return '서버 오류가 발생했습니다';
    }
    return '오류가 발생했습니다';
  }

  /// 마지막 업데이트 시간 포맷팅
  String _formatLastUpdated(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inMinutes < 1) {
      return '방금 전 업데이트';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전 업데이트';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전 업데이트';
    } else {
      return '${lastUpdated.month}/${lastUpdated.day} ${lastUpdated.hour}:${lastUpdated.minute.toString().padLeft(2, '0')}';
    }
  }
}
