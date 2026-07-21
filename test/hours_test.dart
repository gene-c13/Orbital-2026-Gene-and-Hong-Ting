import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:after_hours/utils/hours.dart';

// hoursOut now lives in lib/utils/hours.dart and is imported here, so this
// test actually guards the code create_post_screen.dart runs.

void main() {
  final date = DateTime(2026, 6, 24);

  test('same-day session calculates correctly', () {
    final result = hoursOut(date, const TimeOfDay(hour: 22, minute: 0), const TimeOfDay(hour: 23, minute: 30));
    expect(result, 1.5);
  });

  test('overnight session crosses midnight correctly', () {
    final result = hoursOut(date, const TimeOfDay(hour: 22, minute: 0), const TimeOfDay(hour: 2, minute: 0));
    expect(result, 4.0);
  });

  test('zero duration returns zero', () {
    final result = hoursOut(date, const TimeOfDay(hour: 22, minute: 0), const TimeOfDay(hour: 22, minute: 0));
    expect(result, 0.0);
  });

  test('ending exactly at midnight counts as crossing to the next day', () {
    final result = hoursOut(date, const TimeOfDay(hour: 22, minute: 0), const TimeOfDay(hour: 0, minute: 0));
    expect(result, 2.0);
  });

  test('a full 24-hour session', () {
    final result = hoursOut(date, const TimeOfDay(hour: 12, minute: 0), const TimeOfDay(hour: 12, minute: 0));
    // start == end, so isBefore is false and this reads as 0, not 24 -
    // documenting the current behaviour rather than asserting it's ideal.
    expect(result, 0.0);
  });
}
