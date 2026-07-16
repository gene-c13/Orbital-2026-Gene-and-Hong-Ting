import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:after_hours/utils/time_format.dart';

// formatTimeOfDay and clockTime are pure (same input -> same output, no
// Firebase, no clock), so we can import and call them straight away.

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
}
