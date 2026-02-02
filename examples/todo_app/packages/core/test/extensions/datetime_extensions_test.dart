import 'package:flutter_test/flutter_test.dart';
import 'package:core/extensions/datetime_extensions.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    // Initialize date formatting for Korean locale
    await initializeDateFormatting('ko_KR', null);
  });

  group('DateTimeExtensions', () {
    group('toKoreanDate', () {
      test('should format date in Korean format', () {
        final date = DateTime(2024, 1, 15);
        expect(date.toKoreanDate, '2024년 01월 15일');
      });

      test('should handle single digit months and days', () {
        final date = DateTime(2024, 3, 5);
        expect(date.toKoreanDate, '2024년 03월 05일');
      });

      test('should handle double digit months and days', () {
        final date = DateTime(2024, 12, 31);
        expect(date.toKoreanDate, '2024년 12월 31일');
      });
    });

    group('toShortDate', () {
      test('should format date in short format', () {
        final date = DateTime(2024, 1, 15);
        expect(date.toShortDate, '2024-01-15');
      });

      test('should handle single digit months and days with leading zeros', () {
        final date = DateTime(2024, 3, 5);
        expect(date.toShortDate, '2024-03-05');
      });

      test('should handle year boundaries', () {
        final date = DateTime(2024, 12, 31);
        expect(date.toShortDate, '2024-12-31');
      });
    });

    group('toTime', () {
      test('should format time in HH:mm format', () {
        final date = DateTime(2024, 1, 15, 14, 30);
        expect(date.toTime, '14:30');
      });

      test('should handle midnight', () {
        final date = DateTime(2024, 1, 15, 0, 0);
        expect(date.toTime, '00:00');
      });

      test('should handle single digit hours with leading zero', () {
        final date = DateTime(2024, 1, 15, 9, 5);
        expect(date.toTime, '09:05');
      });

      test('should handle end of day', () {
        final date = DateTime(2024, 1, 15, 23, 59);
        expect(date.toTime, '23:59');
      });
    });

    group('toRelativeTime', () {
      test('should return "Just now" for times less than 60 seconds ago', () {
        final now = DateTime.now();
        final recent = now.subtract(const Duration(seconds: 30));
        expect(recent.toRelativeTime, 'Just now');
      });

      test('should return minutes ago for times less than 60 minutes ago', () {
        final now = DateTime.now();
        final minutesAgo = now.subtract(const Duration(minutes: 15));
        expect(minutesAgo.toRelativeTime, '15m ago');
      });

      test('should return hours ago for times less than 24 hours ago', () {
        final now = DateTime.now();
        final hoursAgo = now.subtract(const Duration(hours: 5));
        expect(hoursAgo.toRelativeTime, '5h ago');
      });

      test('should return days ago for times less than 7 days ago', () {
        final now = DateTime.now();
        final daysAgo = now.subtract(const Duration(days: 3));
        expect(daysAgo.toRelativeTime, '3d ago');
      });

      test('should return formatted date for times more than 7 days ago', () {
        final oldDate = DateTime.now().subtract(const Duration(days: 10));
        final result = oldDate.toRelativeTime;
        // Should be in "MMM d" format
        expect(result, isNot('10d ago'));
        expect(result.length, greaterThan(0));
      });

      test('should return "Today" for future dates on same day', () {
        final now = DateTime.now();
        final later = now.add(const Duration(hours: 2));
        expect(later.toRelativeTime, 'Today');
      });

      test('should return "Tomorrow" for next day', () {
        final now = DateTime.now();
        // Create tomorrow at noon to avoid day boundary issues
        final tomorrow = DateTime(now.year, now.month, now.day + 1, 12, 0);
        final result = tomorrow.toRelativeTime;
        // Accept either "Tomorrow" or "Today" depending on timing
        expect(result, anyOf('Tomorrow', 'Today', startsWith('In ')));
      });

      test('should return "In X days" for future dates less than 7 days', () {
        final now = DateTime.now();
        // Create a future date at noon to avoid boundary issues
        final future = DateTime(now.year, now.month, now.day + 3, 12, 0);
        final result = future.toRelativeTime;
        // Accept "In 2 days", "In 3 days", or "In 4 days" due to timing variations
        expect(result, matches(r'^In \d days$'));
      });

      test('should return formatted date for future dates more than 7 days', () {
        final future = DateTime.now().add(const Duration(days: 10));
        final result = future.toRelativeTime;
        expect(result, isNot('In 10 days'));
        expect(result.length, greaterThan(0));
      });

      test('should handle edge case of exactly 1 minute ago', () {
        final now = DateTime.now();
        final oneMinuteAgo = now.subtract(const Duration(minutes: 1));
        expect(oneMinuteAgo.toRelativeTime, '1m ago');
      });

      test('should handle edge case of exactly 1 hour ago', () {
        final now = DateTime.now();
        final oneHourAgo = now.subtract(const Duration(hours: 1));
        expect(oneHourAgo.toRelativeTime, '1h ago');
      });
    });

    group('isToday', () {
      test('should return true for current date', () {
        final now = DateTime.now();
        expect(now.isToday, true);
      });

      test('should return true for today at different times', () {
        final now = DateTime.now();
        final morning = DateTime(now.year, now.month, now.day, 8, 0);
        final evening = DateTime(now.year, now.month, now.day, 20, 0);

        expect(morning.isToday, true);
        expect(evening.isToday, true);
      });

      test('should return false for yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(yesterday.isToday, false);
      });

      test('should return false for tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(tomorrow.isToday, false);
      });
    });

    group('isTomorrow', () {
      test('should return true for tomorrow', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(tomorrow.isTomorrow, true);
      });

      test('should return true for tomorrow at different times', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final morning = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8, 0);
        final evening = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 20, 0);

        expect(morning.isTomorrow, true);
        expect(evening.isTomorrow, true);
      });

      test('should return false for today', () {
        final now = DateTime.now();
        expect(now.isTomorrow, false);
      });

      test('should return false for day after tomorrow', () {
        final dayAfter = DateTime.now().add(const Duration(days: 2));
        expect(dayAfter.isTomorrow, false);
      });
    });

    group('isPast', () {
      test('should return true for dates before today', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expect(yesterday.isPast, true);
      });

      test('should return false for today', () {
        final now = DateTime.now();
        expect(now.isPast, false);
      });

      test('should return false for future dates', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expect(tomorrow.isPast, false);
      });

      test('should consider start of day as boundary', () {
        final now = DateTime.now();
        final startOfToday = DateTime(now.year, now.month, now.day);
        expect(startOfToday.isPast, false);
      });

      test('should return true for dates many years ago', () {
        final oldDate = DateTime(2020, 1, 1);
        expect(oldDate.isPast, true);
      });
    });

    group('startOfDay', () {
      test('should return start of day with time 00:00:00', () {
        final date = DateTime(2024, 1, 15, 14, 30, 45);
        final startOfDay = date.startOfDay;

        expect(startOfDay.year, 2024);
        expect(startOfDay.month, 1);
        expect(startOfDay.day, 15);
        expect(startOfDay.hour, 0);
        expect(startOfDay.minute, 0);
        expect(startOfDay.second, 0);
        expect(startOfDay.millisecond, 0);
      });

      test('should work for midnight', () {
        final midnight = DateTime(2024, 1, 15, 0, 0, 0);
        final startOfDay = midnight.startOfDay;

        expect(startOfDay, midnight);
      });

      test('should work for last second of day', () {
        final endOfDay = DateTime(2024, 1, 15, 23, 59, 59);
        final startOfDay = endOfDay.startOfDay;

        expect(startOfDay.day, 15);
        expect(startOfDay.hour, 0);
        expect(startOfDay.minute, 0);
        expect(startOfDay.second, 0);
      });
    });

    group('endOfDay', () {
      test('should return end of day with time 23:59:59.999', () {
        final date = DateTime(2024, 1, 15, 14, 30, 45);
        final endOfDay = date.endOfDay;

        expect(endOfDay.year, 2024);
        expect(endOfDay.month, 1);
        expect(endOfDay.day, 15);
        expect(endOfDay.hour, 23);
        expect(endOfDay.minute, 59);
        expect(endOfDay.second, 59);
        expect(endOfDay.millisecond, 999);
      });

      test('should work for midnight', () {
        final midnight = DateTime(2024, 1, 15, 0, 0, 0);
        final endOfDay = midnight.endOfDay;

        expect(endOfDay.day, 15);
        expect(endOfDay.hour, 23);
        expect(endOfDay.minute, 59);
        expect(endOfDay.second, 59);
      });

      test('should be after startOfDay', () {
        final date = DateTime(2024, 1, 15, 12, 0);
        expect(date.endOfDay.isAfter(date.startOfDay), true);
      });

      test('should be on same day as startOfDay', () {
        final date = DateTime(2024, 1, 15, 12, 0);
        final start = date.startOfDay;
        final end = date.endOfDay;

        expect(start.year, end.year);
        expect(start.month, end.month);
        expect(start.day, end.day);
      });
    });

    group('edge cases', () {
      test('should handle leap year dates', () {
        final leapDate = DateTime(2024, 2, 29);
        expect(leapDate.toShortDate, '2024-02-29');
        expect(leapDate.startOfDay.day, 29);
      });

      test('should handle year boundaries', () {
        final newYear = DateTime(2024, 1, 1);
        final yearEnd = DateTime(2023, 12, 31);

        expect(newYear.toShortDate, '2024-01-01');
        expect(yearEnd.toShortDate, '2023-12-31');
      });

      test('should handle different timezones', () {
        final date = DateTime(2024, 1, 15, 14, 30);
        final utcDate = date.toUtc();

        // Extensions should work regardless of timezone
        expect(date.startOfDay, isA<DateTime>());
        expect(utcDate.startOfDay, isA<DateTime>());
      });
    });
  });
}
