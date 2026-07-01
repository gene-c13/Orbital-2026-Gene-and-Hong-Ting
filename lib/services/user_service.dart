import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:after_hours/models/user.dart';

/// Centralises reads of the `users` collection so screens work with typed
/// [AppUser] objects instead of raw Firestore maps (same role EventService
/// plays for `events`).
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Fetches a single user once. Returns null if the doc doesn't exist.
  Future<AppUser?> getUser(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Live updates for a single user — e.g. a profile screen that should
  /// reflect edits (like a new avatar) without needing a manual refresh.
  Stream<AppUser?> userStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  /// Fetches multiple users by uid in as few queries as possible — for
  /// attendee lists, friend lists, chat participant lists, etc., instead of
  /// firing one FutureBuilder per uid. Firestore's `whereIn` only accepts up
  /// to 10 values per query, so this batches automatically for longer lists.
  Future<List<AppUser>> getUsers(List<String> uids) async {
    if (uids.isEmpty) return [];

    final results = <AppUser>[];
    for (var i = 0; i < uids.length; i += 10) {
      final end = (i + 10 > uids.length) ? uids.length : i + 10;
      final batch = uids.sublist(i, end);

      final snap = await _usersCollection
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      results.addAll(snap.docs.map(
        (d) => AppUser.fromFirestore(d.data() as Map<String, dynamic>, d.id),
      ));
    }
    return results;
  }
}
