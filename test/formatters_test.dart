import 'package:flutter_test/flutter_test.dart';
import 'package:servio/core/utils/formatters.dart';

/// Dates decide what a student's attendance says, so the rule that matters
/// is: calendar days are read in UTC (they're stored as midnight UTC),
/// while moments are shown in the viewer's local time.
void main() {
  group('Formatters', () {
    test('shows a calendar day in UTC, whatever the local timezone', () {
      // Midnight UTC is the previous evening in the Americas; read as local
      // time this day would come out as the 21st.
      final day = DateTime.utc(2026, 9, 22);
      expect(Formatters.day(day), 'Tue, 22 Sep 2026');
      expect(Formatters.date(day), '22 Sep 2026');
    });

    test('shows a moment in local time', () {
      final moment = DateTime(2026, 9, 22, 9, 5);
      expect(Formatters.time(moment), '09:05');
      expect(Formatters.dateTime(moment), '22 Sep 2026, 09:05');
    });

    test('shortens a date range within one year', () {
      expect(
        Formatters.dateRange(
          DateTime.utc(2026, 6, 1),
          DateTime.utc(2026, 9, 30),
        ),
        '1 Jun – 30 Sep 2026',
      );
      expect(
        Formatters.dateRange(
          DateTime.utc(2025, 12, 1),
          DateTime.utc(2026, 3, 1),
        ),
        '1 Dec 2025 – 1 Mar 2026',
      );
    });

    test('describes how long ago something happened', () {
      final now = DateTime(2026, 9, 22, 12);
      expect(
        Formatters.relative(
          now.subtract(const Duration(seconds: 20)),
          now: now,
        ),
        'just now',
      );
      expect(
        Formatters.relative(now.subtract(const Duration(minutes: 5)), now: now),
        '5 min ago',
      );
      expect(
        Formatters.relative(now.subtract(const Duration(hours: 3)), now: now),
        '3 h ago',
      );
      expect(
        Formatters.relative(now.subtract(const Duration(days: 1)), now: now),
        startsWith('yesterday'),
      );
      expect(
        Formatters.relative(now.subtract(const Duration(days: 9)), now: now),
        '13 Sep',
      );
    });

    test('counts with the right plural', () {
      expect(Formatters.count(1, 'day'), '1 day');
      expect(Formatters.count(3, 'day'), '3 days');
      expect(Formatters.count(1, 'entry', 'entries'), '1 entry');
      expect(Formatters.count(0, 'entry', 'entries'), '0 entries');
    });

    test('greets by time of day', () {
      expect(Formatters.greeting(DateTime(2026, 9, 22, 8)), 'Good morning');
      expect(Formatters.greeting(DateTime(2026, 9, 22, 13)), 'Good afternoon');
      expect(Formatters.greeting(DateTime(2026, 9, 22, 19)), 'Good evening');
    });

    test('today is a midnight-UTC day, matching stored attendance dates', () {
      final today = Formatters.todayUtc();
      expect(today.isUtc, isTrue);
      expect([today.hour, today.minute, today.second], [0, 0, 0]);
    });
  });
}
