import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:after_hours/models/event.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _eventsCollection => _firestore.collection('events');

  Stream<List<Event>> getEventsByDateStream(String date) {
    return _eventsCollection
        .where('date', isEqualTo: date)
        .orderBy('sort_order')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Event.fromFirestore(d.data() as Map<String, dynamic>, d.id)).toList());
  }

  Stream<List<Event>> getAllEventsStream() {
    final sgt = DateTime.now().toUtc().add(const Duration(hours: 8));
    final todayKey = DateFormat('yyyy-MM-dd').format(sgt);

    return _eventsCollection
        .where('date', isGreaterThanOrEqualTo: todayKey)
        .orderBy('date')
        .orderBy('sort_order')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Event.fromFirestore(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }
}
