import 'package:flutter/material.dart';

/// OpenWeatherMap 날씨 아이콘 코드를 Flutter Icons로 매핑
class WeatherIcon extends StatelessWidget {
  final String iconCode;
  final double size;
  final Color? color;

  const WeatherIcon({
    super.key,
    required this.iconCode,
    this.size = 48.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      _getIconData(iconCode),
      size: size,
      color: color ?? Theme.of(context).colorScheme.primary,
    );
  }

  /// 날씨 아이콘 코드에 따른 IconData 반환
  ///
  /// OpenWeatherMap API icon codes:
  /// - 01d/01n: Clear sky (해)
  /// - 02d/02n: Few clouds (구름 조금)
  /// - 03d/03n: Scattered clouds (구름 많음)
  /// - 04d/04n: Broken clouds (흐림)
  /// - 09d/09n: Shower rain (소나기)
  /// - 10d/10n: Rain (비)
  /// - 11d/11n: Thunderstorm (천둥번개)
  /// - 13d/13n: Snow (눈)
  /// - 50d/50n: Mist (안개)
  static IconData _getIconData(String iconCode) {
    // 아이콘 코드에서 숫자 부분만 추출 (d/n 제거)
    final code = iconCode.substring(0, 2);

    switch (code) {
      case '01': // Clear sky
        return Icons.wb_sunny;
      case '02': // Few clouds
        return Icons.wb_cloudy;
      case '03': // Scattered clouds
        return Icons.cloud;
      case '04': // Broken clouds
        return Icons.cloud_queue;
      case '09': // Shower rain
        return Icons.grain;
      case '10': // Rain
        return Icons.umbrella;
      case '11': // Thunderstorm
        return Icons.thunderstorm;
      case '13': // Snow
        return Icons.ac_unit;
      case '50': // Mist
        return Icons.foggy;
      default:
        return Icons.wb_cloudy;
    }
  }

  /// 날씨 상태에 따른 색상 반환
  static Color getWeatherColor(String iconCode, BuildContext context) {
    final code = iconCode.substring(0, 2);
    final colorScheme = Theme.of(context).colorScheme;

    switch (code) {
      case '01': // Clear sky
        return Colors.orange;
      case '02': // Few clouds
        return Colors.blueGrey;
      case '03': // Scattered clouds
      case '04': // Broken clouds
        return Colors.grey;
      case '09': // Shower rain
      case '10': // Rain
        return Colors.blue;
      case '11': // Thunderstorm
        return Colors.deepPurple;
      case '13': // Snow
        return Colors.lightBlue;
      case '50': // Mist
        return Colors.blueGrey.shade300;
      default:
        return colorScheme.primary;
    }
  }
}
