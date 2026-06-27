import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double hoursOut(DateTime date, TimeOfDay start, TimeOfDay end) {
  final base = DateTime(date.year, date.month, date.day);
  var s = base.add(Duration(hours: start.hour, minutes: start.minute));
  var e = base.add(Duration(hours: end.hour, minutes: end.minute));
  if (e.isBefore(s)) e = e.add(const Duration(days: 1));
  return e.difference(s).inMinutes / 60.0;
}

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
}