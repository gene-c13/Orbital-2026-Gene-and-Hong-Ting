import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User> register({
    required String email,
    required String password,
    required String username,
  }) async {
    final usernameRef = _db.collection('usernames').doc(username);

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;

    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(usernameRef);
        if (snap.exists) throw Exception('username_taken');
        tx.set(_db.collection('users').doc(user.uid), {
          'username': username,
          'hours_this_month':  0,
          'events_this_month': 0,
          'puke_count':        0,
          'total_events':      0,
          'favourite_venue':   '',
          'favourite_genre':   '',
          'clubs_visited':     [],
        });
        tx.set(usernameRef, {'uid': user.uid});
      });
    } catch (e) {
      await user.delete();
      rethrow;
    }

    await user.sendEmailVerification();
    return user;
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return credential.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<bool> checkEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  bool get hasDisplayName =>
      (_auth.currentUser?.displayName ?? '').isNotEmpty;

  String get currentDisplayName {
    final user = _auth.currentUser;
    if (user == null) return 'Raver';
    return user.displayName ?? user.email?.split('@').first ?? 'Raver';
  }

  Future<void> completeProfileSetup({
    required String displayName,
    String favouriteVenue = '',
    String? favouriteGenre,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('no_user');

    await user.updateDisplayName(displayName);
    await _db.collection('users').doc(user.uid).set({
      'display_name':    displayName,
      'favourite_venue': favouriteVenue,
      'favourite_genre': favouriteGenre ?? '',
    }, SetOptions(merge: true));
  }
}
