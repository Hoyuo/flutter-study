import 'package:intl/intl.dart';

/// DateTime 확장 메서드
extension DateTimeExtensions on DateTime {
  /// 한국어 형식으로 날짜 포맷 (yyyy년 MM월 dd일)
  String get toKoreanDate {
    return DateFormat('yyyy년 MM월 dd일', 'ko_KR').format(this);
  }

  /// 한국어 형식으로 날짜 + 시간 포맷 (yyyy년 MM월 dd일 HH:mm)
  String get toKoreanDateTime {
    return DateFormat('yyyy년 MM월 dd일 HH:mm', 'ko_KR').format(this);
  }

  /// 짧은 날짜 형식 (yyyy-MM-dd)
  String get toShortDate {
    return DateFormat('yyyy-MM-dd').format(this);
  }

  /// 시간 형식 (HH:mm)
  String get toTime {
    return DateFormat('HH:mm').format(this);
  }

  /// 상대적인 시간 표시 (방금 전, 1시간 전 등)
  String get toRelativeTime {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}주 전';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}개월 전';
    } else {
      return '${(difference.inDays / 365).floor()}년 전';
    }
  }

  /// 오늘인지 확인
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// 어제인지 확인
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// 이번 주인지 확인
  bool get isThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return isAfter(startOfWeek) && isBefore(endOfWeek);
  }

  /// 이번 달인지 확인
  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  /// 이번 해인지 확인
  bool get isThisYear {
    final now = DateTime.now();
    return year == now.year;
  }

  /// 날짜 시작 시간 (00:00:00)
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// 날짜 종료 시간 (23:59:59)
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }

  /// 주의 시작일 (월요일)
  DateTime get startOfWeek {
    return subtract(Duration(days: weekday - 1));
  }

  /// 주의 종료일 (일요일)
  DateTime get endOfWeek {
    return add(Duration(days: 7 - weekday));
  }

  /// 월의 시작일
  DateTime get startOfMonth {
    return DateTime(year, month, 1);
  }

  /// 월의 종료일
  DateTime get endOfMonth {
    return DateTime(year, month + 1, 0);
  }
}
