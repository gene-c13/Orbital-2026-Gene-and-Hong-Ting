import 'package:cloud_firestore/cloud_firestore.dart';

class FriendService {
  final _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> searchByUsername(String username) async {
    final usernameDoc = await _db
        .collection('usernames')
        .doc(username.toLowerCase().trim())
        .get();

    if (!usernameDoc.exists) return null;

    final uid = usernameDoc.data()?['uid'] as String?;
    if (uid == null) return null;

    final userDoc = await _db.collection('users').doc(uid).get();
    if (!userDoc.exists) return null;

    return {'uid': uid, ...?userDoc.data()};
  }

  Future<void> sendFriendRequest(String fromUid, String toUid) async {
    final existing = await _db
        .collection('friend_requests')
        .where('from_uid', isEqualTo: fromUid)
        .where('to_uid', isEqualTo: toUid)
        .get();

    if (existing.docs.isNotEmpty) return;

    await _db.collection('friend_requests').add({
      'from_uid': fromUid,
      'to_uid': toUid,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> incomingRequests(String uid) {
    return _db
        .collection('friend_requests')
        .where('to_uid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> acceptRequest(String requestId, String fromUid, String toUid) async {
    final batch = _db.batch();

    batch.update(_db.collection('friend_requests').doc(requestId), {
      'status': 'accepted',
    });

    batch.set(
      _db.collection('users').doc(toUid).collection('friends').doc(fromUid),
      {'since': FieldValue.serverTimestamp()},
    );

    batch.set(
      _db.collection('users').doc(fromUid).collection('friends').doc(toUid),
      {'since': FieldValue.serverTimestamp()},
    );

    await batch.commit();
  }

  Future<void> rejectRequest(String requestId) async {
    await _db.collection('friend_requests').doc(requestId).update({
      'status': 'rejected',
    });
  }

  Future<bool> isFriend(String currentUid, String otherUid) async {
    final doc = await _db
        .collection('users')
        .doc(currentUid)
        .collection('friends')
        .doc(otherUid)
        .get();
    return doc.exists;
  }

  Future<bool> hasPendingRequest(String fromUid, String toUid) async {
    final result = await _db
        .collection('friend_requests')
        .where('from_uid', isEqualTo: fromUid)
        .where('to_uid', isEqualTo: toUid)
        .where('status', isEqualTo: 'pending')
        .get();
    return result.docs.isNotEmpty;
  }
}