import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostService {
  final _db = FirebaseFirestore.instance;

  Stream<List<QueryDocumentSnapshot>> feedStream(String uid) {
    final publicStream = _db
        .collection('posts')
        .where('is_public', isEqualTo: true)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots();

    final ownStream = _db
        .collection('posts')
        .where('uid', isEqualTo: uid)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots();

    QuerySnapshot? latestPublic;
    QuerySnapshot? latestOwn;

    List<QueryDocumentSnapshot> merge() {
      final publicDocs = latestPublic?.docs ?? [];
      final ownDocs    = latestOwn?.docs   ?? [];

      final seen = <String>{};
      final merged = <QueryDocumentSnapshot>[];
      for (final doc in [...publicDocs, ...ownDocs]) {
        if (seen.add(doc.id)) merged.add(doc);
      }
      merged.sort((a, b) {
        final at = (a.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
        final bt = (b.data() as Map<String, dynamic>)['created_at'] as Timestamp?;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
      return merged;
    }

    final controller = StreamController<List<QueryDocumentSnapshot>>.broadcast();

    final publicSub = publicStream.listen(
      (snap) { latestPublic = snap; controller.add(merge()); },
      onError: controller.addError,
    );
    final ownSub = ownStream.listen(
      (snap) { latestOwn = snap; controller.add(merge()); },
      onError: controller.addError,
    );

    controller.onCancel = () {
      publicSub.cancel();
      ownSub.cancel();
      controller.close();
    };

    return controller.stream;
  }

  Stream<QuerySnapshot> commentsStream(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('created_at', descending: false)
        .snapshots();
  }

  Future<String> uploadPostImage(String uid, Uint8List bytes) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = FirebaseStorage.instance.ref('posts/$uid/$timestamp.jpg');
    await ref.putData(bytes);
    return ref.getDownloadURL();
  }

  // creates the post document and updates the user's stats in one atomic batch
  // so a network failure can't leave a post without stats or stats without a post
  Future<void> createPost({
    required String uid,
    required String displayName,
    required String username,
    required String caption,
    required String venue,
    required String eventTag,
    required double? rating,
    required String imageUrl,
    required bool puked,
    required String nightDate,
    required String? startTime,
    required String? endTime,
    required double hoursOut,
    required bool isPublic,
  }) async {
    final batch = _db.batch();

    // pre-generate a doc ref so we can batch.set() instead of posts.add()
    // (add() can't be used in a batch because it auto-generates the ID internally)
    final postRef = _db.collection('posts').doc();
    batch.set(postRef, {
      'uid':           uid,
      'display_name':  displayName,
      'username':      username,
      'caption':       caption,
      'venue_tag':     venue,
      'event_tag':     eventTag,
      'rating':        rating,
      'image_url':     imageUrl,
      'likes':         [],
      'comment_count': 0,
      'puked':         puked,
      'night_date':    nightDate,
      'start_time':    startTime,
      'end_time':      endTime,
      'hours_out':     hoursOut > 0 ? hoursOut : null,
      'is_public':     isPublic,
      'created_at':    FieldValue.serverTimestamp(),
    });

    final Map<String, dynamic> updates = {
      'events_this_month': FieldValue.increment(1),
      'total_events':      FieldValue.increment(1),
    };
    if (hoursOut > 0)       updates['hours_this_month'] = FieldValue.increment(hoursOut);
    if (puked)              updates['puke_count']        = FieldValue.increment(1);
    if (venue.isNotEmpty)   updates['clubs_visited']     = FieldValue.arrayUnion([venue]);

    batch.set(
      _db.collection('users').doc(uid),
      updates,
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<void> toggleLike(String postId, String uid, bool currentlyLiked) async {
    final ref = _db.collection('posts').doc(postId);
    if (currentlyLiked) {
      await ref.update({'likes': FieldValue.arrayRemove([uid])});
    } else {
      await ref.update({'likes': FieldValue.arrayUnion([uid])});
    }
  }

  // keeps existing posts in sync when the account-level privacy setting changes,
// so old posts don't keep whatever visibility they were created with
  Future<void> syncVisibility(String uid, bool isPublic) async {
    final ownPosts = await _db
        .collection('posts')
        .where('uid', isEqualTo: uid)
        .get(); //look for all posts by user

    final batch = _db.batch();
    for (final doc in ownPosts.docs) { //iterate and update every post's isPublic field
      batch.update(doc.reference, {'is_public': isPublic});
    }
    await batch.commit();
  }

  Future<void> addComment(String postId, String uid, String username, String text, String? photoUrl) async {
    final batch = _db.batch();
    final commentRef = _db.collection('posts').doc(postId).collection('comments').doc();
    batch.set(commentRef, {
      'uid': uid,
      'username': username,
      'photo_url':photoUrl,
      'text': text,
      'created_at': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('posts').doc(postId), {
      'comment_count': FieldValue.increment(1),
    });
    await batch.commit();
  }
}
