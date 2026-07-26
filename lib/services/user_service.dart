import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:after_hours/models/user.dart';
import 'package:after_hours/services/post_service.dart';

//all reads and writes to the users collection live here so screens get
//AppUser objects instead of raw firestore maps. same idea as EventService
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');

  //grabs one user once, null if the doc doesn't exist
  Future<AppUser?> getUser(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
  }

  //live version of getUser, so a profile screen updates itself when
  //something like the avatar changes
  Stream<AppUser?> userStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  //fetch a bunch of users at once, used for attendee and friend lists
  Future<List<AppUser>> getUsers(List<String> uids) async {
    if (uids.isEmpty) return [];

    final users = <AppUser>[];
    for (final uid in uids) {
      final u = await getUser(uid);
      if (u != null) users.add(u);
    }
    return users;
  }

  Future<List<AppUser>> searchByUsernamePrefix(String query) async {
    final snap = await _usersCollection
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query')
        .limit(8)
        .get();
    return snap.docs
        .map((doc) => AppUser.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<String> _uploadAvatar(String uid, Uint8List bytes) async {
    final ref = FirebaseStorage.instance.ref('avatars/$uid.jpg');
    await ref.putData(bytes);
    return ref.getDownloadURL();
  }

  //saves everything the edit profile sheet can change in one go, including
  //the display name which has to go to both auth and firestore
  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required String favouriteVenue,
    required String favouriteGenre,
    required bool isPublic,
    required String bio,
    Uint8List? avatarBytes,
  }) async {
    //upload the avatar first since it's the step most likely to fail, that
    //way we don't end up with a half saved profile
    String? photoUrl;
    if (avatarBytes != null) {
      photoUrl = await _uploadAvatar(uid, avatarBytes);
    }

    await FirebaseAuth.instance.currentUser?.updateDisplayName(displayName);

    final data = <String, dynamic>{
      'display_name':    displayName,
      'favourite_venue': favouriteVenue,
      'favourite_genre': favouriteGenre,
      'is_public':       isPublic,
      'bio':             bio,
    };
    if (photoUrl != null) data['photo_url'] = photoUrl;

    await _usersCollection.doc(uid).set(data, SetOptions(merge: true)); //updating doc with new fields, .set is safer than .update as latter requires doc to exist alr
    await PostService().syncVisibility(uid, isPublic);  
  }
}
