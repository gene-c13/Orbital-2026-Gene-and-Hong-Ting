import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:after_hours/models/user.dart';
import 'package:after_hours/services/friend_service.dart';

/// Centralises reads and writes of the `users` collection so screens work
/// with typed [AppUser] objects instead of raw Firestore maps (same role
/// EventService plays for `events`).
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

  /// Fetches multiple users by uid — for attendee lists, friend lists,
  /// chat participant lists, etc.
  Future<List<AppUser>> getUsers(List<String> uids) async {
    if (uids.isEmpty) return [];

    final users = <AppUser>[];
    for (final uid in uids) {
      final u = await getUser(uid);
      if (u != null) users.add(u);
    }
    return users;
  }

  Future<String> _uploadAvatar(String uid, Uint8List bytes) async {
    final ref = FirebaseStorage.instance.ref('avatars/$uid.jpg');
    await ref.putData(bytes);
    return ref.getDownloadURL();
  }

  /// Saves profile-edit changes in one place: display name (both Firebase
  /// Auth and Firestore), favourite venue/genre, the public/private toggle,
  /// and — if the user picked a new one — their avatar. Called from
  /// EditProfileSheet's save button.
  Future<void> updateProfile({
    required String uid,
    required String displayName,
    required String favouriteVenue,
    required String favouriteGenre,
    required bool isPublic,
    Uint8List? avatarBytes,
  }) async {
    // upload avatar first — it's the most likely step to fail, and doing it
    // before the Auth/Firestore writes means we never end up with a half-saved profile
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
    };
    if (photoUrl != null) data['photo_url'] = photoUrl;

    await _usersCollection.doc(uid).set(data, SetOptions(merge: true));
  }

  /// Whether [currentUid] should be allowed to see a post authored by
  /// [authorUid]: always true for your own posts, true if the author's
  /// profile is public, otherwise gated on the existing friends
  /// relationship (a stand-in until following/followers exists).
  Future<bool> isPostVisible(String currentUid, String authorUid) async {
    if (authorUid == currentUid) return true;

    final author = await getUser(authorUid);
    if (author == null || author.isPublic) return true;

    return FriendService().isFriend(currentUid, authorUid);
  }
}
