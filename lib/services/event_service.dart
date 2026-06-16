import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:after_hours/models/event.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _eventsCollection => _firestore.collection('events');

  Stream<List<Event>> getEventsStream() {
    return _eventsCollection
        .orderBy('time')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Event.fromFirestore(d.data() as Map<String, dynamic>, d.id)).toList());
  }

  Stream<List<Event>> getEventsByDateStream(String date) {
    return _eventsCollection
        .where('date', isEqualTo: date)
        .orderBy('sort_order')
        .snapshots()
        .map((snap) => snap.docs.map((d) => Event.fromFirestore(d.data() as Map<String, dynamic>, d.id)).toList());
  }

  Future<int> getEventCountForDate(String date) async {
    final snap = await _eventsCollection.where('date', isEqualTo: date).get();
    return snap.docs.length;
  }
}
