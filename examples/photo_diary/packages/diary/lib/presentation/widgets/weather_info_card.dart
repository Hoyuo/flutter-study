import 'package:flutter/material.dart';
import 'package:core/core.dart';

/// 날씨 정보를 표시하는 카드 위젯
///
/// 날씨 아이콘, 온도, 설명을 표시합니다.
class WeatherInfoCard extends StatelessWidget {
  /// 날씨 정보
  final WeatherInfo weather;

  /// 컴팩트 모드 여부 (작은 크기로 표시)
  final bool compact;

  const WeatherInfoCard({
    super.key,
    required this.weather,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (compact) {
      // 컴팩트 모드: 아이콘 + 온도만 표시
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 날씨 아이콘
          _buildWeatherIcon(context, size: 20),
          const SizedBox(width: 4),

          // 온도
          Text(
            '${weather.temperature.round()}°',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    // 일반 모드: 카드로 표시
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // 날씨 아이콘
            _buildWeatherIcon(context, size: 48),
            const SizedBox(width: 16),

            // 날씨 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 온도
                  Text(
                    '${weather.temperature.round()}°C',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // 날씨 상태
                  Text(
                    weather.condition,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  // 습도 (있는 경우)
                  if (weather.humidity != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '습도: ${weather.humidity!.round()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 날씨 아이콘 위젯 빌드
  Widget _buildWeatherIcon(BuildContext context, {required double size}) {
    // 날씨 상태에 따라 아이콘 선택
    IconData icon = _getWeatherIcon(weather.condition);
    final colorScheme = Theme.of(context).colorScheme;

    return Icon(
      icon,
      size: size,
      color: colorScheme.primary,
    );
  }

  /// 날씨 상태 문자열에서 아이콘 가져오기
  IconData _getWeatherIcon(String condition) {
    final lowerCondition = condition.toLowerCase();

    if (lowerCondition.contains('clear') || lowerCondition.contains('맑음')) {
      return Icons.wb_sunny;
    } else if (lowerCondition.contains('cloud') ||
        lowerCondition.contains('구름')) {
      return Icons.wb_cloudy;
    } else if (lowerCondition.contains('rain') ||
        lowerCondition.contains('비')) {
      return Icons.umbrella;
    } else if (lowerCondition.contains('snow') ||
        lowerCondition.contains('눈')) {
      return Icons.ac_unit;
    } else if (lowerCondition.contains('thunder') ||
        lowerCondition.contains('번개')) {
      return Icons.flash_on;
    } else if (lowerCondition.contains('fog') ||
        lowerCondition.contains('안개')) {
      return Icons.cloud;
    } else {
      return Icons.wb_sunny;
    }
  }
}
