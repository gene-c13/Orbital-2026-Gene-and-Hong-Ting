import 'package:flutter/material.dart';

// How many hours pass between a start and end time on a given date.
// If end is earlier than start, we assume the session crossed midnight
// (e.g. 10 PM -> 2 AM) and add a day before subtracting.
double hoursOut(DateTime date, TimeOfDay start, TimeOfDay end) {
  final base = DateTime(date.year, date.month, date.day);
  var startTime = base.add(Duration(hours: start.hour, minutes: start.minute));
  var endTime   = base.add(Duration(hours: end.hour,   minutes: end.minute));
  if (endTime.isBefore(startTime)) endTime = endTime.add(const Duration(days: 1));
  return endTime.difference(startTime).inMinutes / 60.0;
}
