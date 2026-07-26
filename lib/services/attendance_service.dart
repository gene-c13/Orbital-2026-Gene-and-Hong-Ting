import 'package:cloud_firestore/cloud_firestore.dart';

//wraps the events/{eventId}/attendees subcollection, one doc per user
//who's going to that event, keyed by uid
class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _attendeesCollection(String eventId) =>
      _firestore.collection('events').doc(eventId).collection('attendees');

  Future<void> markAttending(String eventId, String uid) {
    return _attendeesCollection(eventId).doc(uid).set({
      'joined_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unmarkAttending(String eventId, String uid) {
    return _attendeesCollection(eventId).doc(uid).delete();
  }

  //live list of attendee uids. used to show who's going, and checking if it
  //contains the current uid tells us whether they've already marked going
  Stream<List<String>> attendeeUidsStream(String eventId) {
    return _attendeesCollection(eventId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }
}
