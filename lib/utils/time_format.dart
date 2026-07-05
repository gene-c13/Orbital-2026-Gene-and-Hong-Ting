import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String timeAgo(Timestamp? ts) {
  if (ts == null) return '';
  final diff = DateTime.now().difference(ts.toDate());
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

String clockTime(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String formatTimeOfDay(TimeOfDay t) {
  final h  = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final m  = t.minute.toString().padLeft(2, '0');
  final pm = t.period == DayPeriod.pm ? 'PM' : 'AM';
  return '$h:$m $pm';
}

String chatTimeLabel(Timestamp? ts) {
  if (ts == null) return '';
  final dt     = ts.toDate();
  final hour   = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}
