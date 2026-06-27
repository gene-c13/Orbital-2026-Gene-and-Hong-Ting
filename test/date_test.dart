import 'package:flutter_test/flutter_test.dart';

String dateKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

void main() {
  test('formats single digit month and day with leading zero', () {
    final result = dateKey(DateTime(2026, 6, 4));
    expect(result, '2026-06-04');
  });

  test('formats double digit month and day correctly', () {
    final result = dateKey(DateTime(2026, 12, 25));
    expect(result, '2026-12-25');
  });

  test('formats first day of year correctly', () {
    final result = dateKey(DateTime(2026, 1, 1));
    expect(result, '2026-01-01');
  });
}