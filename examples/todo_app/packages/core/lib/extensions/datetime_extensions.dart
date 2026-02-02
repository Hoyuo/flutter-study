import 'package:intl/intl.dart';

/// DateTime 확장 메서드
extension DateTimeExtensions on DateTime {
  /// 한국어 형식으로 날짜 포맷 (yyyy년 MM월 dd일)
  String get toKoreanDate {
    return DateFormat('yyyy년 MM월 dd일', 'ko_KR').format(this);
  }

  /// 짧은 날짜 형식 (yyyy-MM-dd)
  String get toShortDate {
    return DateFormat('yyyy-MM-dd').format(this);
  }

  /// 시간 형식 (HH:mm)
  String get toTime {
    return DateFormat('HH:mm').format(this);
  }

  /// 상대적인 시간 표시
  String get toRelativeTime {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.isNegative) {
      // Future date
      final futureDiff = this.difference(now);
      if (futureDiff.inDays == 0) {
        return 'Today';
      } else if (futureDiff.inDays == 1) {
        return 'Tomorrow';
      } else if (futureDiff.inDays < 7) {
        return 'In ${futureDiff.inDays} days';
      } else {
        return DateFormat('MMM d').format(this);
      }
    }

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(this);
    }
  }

  /// 오늘인지 확인
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// 내일인지 확인
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// 과거인지 확인
  bool get isPast {
    return isBefore(DateTime.now().startOfDay);
  }

  /// 날짜 시작 시간 (00:00:00)
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// 날짜 종료 시간 (23:59:59)
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }
}
