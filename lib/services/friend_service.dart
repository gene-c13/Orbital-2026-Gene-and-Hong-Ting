import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:after_hours/models/user.dart';
import 'package:after_hours/services/user_service.dart';

class FriendService {
  final _db = FirebaseFirestore.instance;
  final _userService = UserService();

  Future<AppUser?> searchByUsername(String username) async {
    final usernameDoc = await _db
        .collection('usernames')
        .doc(username.toLowerCase().trim())
        .get();

    if (!usernameDoc.exists) return null;

    final uid = usernameDoc.data()?['uid'] as String?;
    if (uid == null) return null;

    return _userService.getUser(uid);
  }

  Future<void> sendFriendRequest(String fromUid, String toUid) async {
    // deterministic doc ID means two rapid taps both write the same document
    // so there's no way to create a duplicate request
    final docId = '${fromUid}_$toUid';
    await _db.collection('friend_requests').doc(docId).set({
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

  Future<void> cancelRequest(String fromUid, String toUid) async {
    await _db.collection('friend_requests').doc('${fromUid}_$toUid').delete();
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

  Future<void> unfriend(String uid, String otherUid) async {
    final isCurrentlyFriend = await isFriend(uid, otherUid);
    if (!isCurrentlyFriend) return;

    final batch = _db.batch();
    batch.delete(_db.collection('users').doc(uid).collection('friends').doc(otherUid));
    batch.delete(_db.collection('users').doc(otherUid).collection('friends').doc(uid));
    await batch.commit();
  }

  Stream<QuerySnapshot> friendsStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('friends')
        .snapshots();
  }

  Future<bool> hasPendingRequest(String fromUid, String toUid) async {
    // check both A→B and B→A so the search screen shows "Sent" or hides "Add"
    // in both directions, since sendFriendRequest uses a deterministic doc ID
    final forward = await _db
        .collection('friend_requests')
        .doc('${fromUid}_$toUid')
        .get();
    if (forward.exists && forward.data()?['status'] == 'pending') return true;

    final reverse = await _db
        .collection('friend_requests')
        .doc('${toUid}_$fromUid')
        .get();
    return reverse.exists && reverse.data()?['status'] == 'pending';
  }
}