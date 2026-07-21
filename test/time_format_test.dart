import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:after_hours/utils/time_format.dart';

// formatTimeOfDay and clockTime are pure (same input -> same output, no
// Firebase, no clock), so we can import and call them straight away.
//
// timeAgo and chatTimeLabel take a Timestamp instead, but they're still
// callable directly - we just build the Timestamp from DateTime.now()
// minus a fixed offset, so each test controls its own "how long ago".

void main() {
  group('formatTimeOfDay (12-hour AM/PM)', () {
    test('midnight shows as 12:00 AM, not 0:00', () {
      expect(formatTimeOfDay(const TimeOfDay(hour: 0, minute: 0)), '12:00 AM');
    });

    test('noon shows as 12:00 PM', () {
      expect(formatTimeOfDay(const TimeOfDay(hour: 12, minute: 0)), '12:00 PM');
    });

    test('an evening time converts to PM with padded minutes', () {
      expect(formatTimeOfDay(const TimeOfDay(hour: 22, minute: 5)), '10:05 PM');
    });
  });

  group('clockTime (24-hour HH:MM)', () {
    test('pads single-digit hours and minutes with a leading zero', () {
      expect(clockTime(DateTime(2026, 7, 13, 9, 5)), '09:05');
    });

    test('leaves double-digit hours and minutes unchanged', () {
      expect(clockTime(DateTime(2026, 7, 13, 23, 45)), '23:45');
    });
  });

  group('timeAgo', () {
    Timestamp ago(Duration d) => Timestamp.fromDate(DateTime.now().subtract(d));

    test('a null timestamp returns an empty string', () {
      expect(timeAgo(null), '');
    });

    test('less than a minute ago shows "now"', () {
      expect(timeAgo(ago(const Duration(seconds: 30))), 'now');
    });

    test('minutes ago shows "Xm ago"', () {
      expect(timeAgo(ago(const Duration(minutes: 5))), '5m ago');
    });

    test('hours ago shows "Xh ago"', () {
      expect(timeAgo(ago(const Duration(hours: 3))), '3h ago');
    });

    test('a day or more ago shows "Xd ago"', () {
      expect(timeAgo(ago(const Duration(days: 2))), '2d ago');
    });

    test('a timestamp in the future still shows "now", not negative time', () {
      final future = Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 10)));
      expect(timeAgo(future), 'now');
    });
  });

  group('chatTimeLabel', () {
    test('a null timestamp returns an empty string', () {
      expect(chatTimeLabel(null), '');
    });

    test('midnight shows as 12:00 AM', () {
      final ts = Timestamp.fromDate(DateTime(2026, 7, 13, 0, 0));
      expect(chatTimeLabel(ts), '12:00 AM');
    });

    test('noon shows as 12:00 PM', () {
      final ts = Timestamp.fromDate(DateTime(2026, 7, 13, 12, 0));
      expect(chatTimeLabel(ts), '12:00 PM');
    });

    test('an afternoon time shows the correct 12-hour value', () {
      final ts = Timestamp.fromDate(DateTime(2026, 7, 13, 13, 5));
      expect(chatTimeLabel(ts), '1:05 PM');
    });
  });
}
