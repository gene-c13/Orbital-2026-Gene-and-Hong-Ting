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
}