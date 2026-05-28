import 'package:cloud_firestore/cloud_firestore.dart';
import 'event.dart';

class EventService {

  // Connection to your Firestore database
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Points to the 'events' collection in Firestore
  CollectionReference get _eventsCollection =>
      _firestore.collection('events');


  // ─────────────────────────────────────────────
  // METHOD 1: All events, live real-time stream
  // ─────────────────────────────────────────────
  // Returns every event ordered by time.
  // Updates automatically if data changes in Firestore.
  Stream<List<Event>> getEventsStream() {
    return _eventsCollection
        .orderBy('time')
        .snapshots()
        .map((QuerySnapshot snapshot) {
          return snapshot.docs
              .map((DocumentSnapshot doc) {
                return Event.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );
              })
              .toList();
        });
  }


  
  // METHOD 2: Events for a specific date, live

  // Returns only events matching the given date string e.g. "2025-06-01"
  // call this method with the new date string
  Stream<List<Event>> getEventsByDateStream(String date) {
    return _eventsCollection
        .where('date', isEqualTo: date)
        .orderBy('time')
        .snapshots()
        .map((QuerySnapshot snapshot) {
          return snapshot.docs
              .map((DocumentSnapshot doc) {
                return Event.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                );
              })
              .toList();
        });
  }


  // METHOD 3: Count of events for a specific date

  // Returns how many events exist on a given date as an integer
  Future<int> getEventCountForDate(String date) async {
    try {
      final QuerySnapshot snapshot = await _eventsCollection
          .where('date', isEqualTo: date)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting event count: $e');
      return 0;
    }
  }
}