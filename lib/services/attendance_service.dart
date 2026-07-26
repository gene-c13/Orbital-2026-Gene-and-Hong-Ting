import 'package:cloud_firestore/cloud_firestore.dart';

/// wraps the `events/{eventId}/attendees` subcollection: one doc per user
/// who's marked themselves as going to that event, keyed by uid.
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

  /// Live list of attendee uids for an event. Used both to render "who's
  /// going" and, by checking whether it contains the current uid, to know
  /// if the current user has already marked themselves attending.
  Stream<List<String>> attendeeUidsStream(String eventId) {
    return _attendeesCollection(eventId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }
}
