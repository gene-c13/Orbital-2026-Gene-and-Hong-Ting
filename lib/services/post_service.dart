import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostService {
  final _db = FirebaseFirestore.instance;

  Stream<List<QueryDocumentSnapshot>> feedStream(String uid) {
  final visibleStream = _db
      .collection('posts')
      .where(Filter.or(
        Filter('is_public', isEqualTo: true),
        Filter('uid', isEqualTo: uid),
      ))
      .orderBy('created_at', descending: true)
      .limit(50)
      .snapshots();

  final friendsListStream = _db
      .collection('users')
      .doc(uid)
      .collection('friends')
      .snapshots();

  List<QueryDocumentSnapshot> latestVisible = [];
  List<QueryDocumentSnapshot> latestFriendPosts = [];

  List<QueryDocumentSnapshot> merge() {
    final seen = <String>{};
    final merged = <QueryDocumentSnapshot>[];
    for (final doc in [...latestVisible, ...latestFriendPosts]) {
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

  void notify() => controller.add(merge()); //shared helper so every callback below doesn't repeat this line

  final visibleSub = visibleStream.listen(
    (snap) { latestVisible = snap.docs; notify(); }, //anon function
    onError: controller.addError,
  );

  // whenever the friends list changes, drop the old friends'-posts listener
  // and start a fresh one scoped to the current friend uids
  StreamSubscription? friendPostsSub; //defining nullable variable

  void onFriendPostsSnapshot(QuerySnapshot snap) { //runs every time new post data arrive from Firestore
    latestFriendPosts = snap.docs;
    notify();
  }

  void onFriendsListChanged(QuerySnapshot friendsSnap) {
    friendPostsSub?.cancel(); //cancel subscription if change in friendsListStream

    final friendUids = friendsSnap.docs.map((d) => d.id).take(30).toList();  //update new friends list
    if (friendUids.isEmpty) {
      latestFriendPosts = [];
      notify();
      return; //return no new posts if no friends
    }

    friendPostsSub = _db //rebuild the query with updated friendsUid
        .collection('posts')
        .where('uid', whereIn: friendUids)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .listen(onFriendPostsSnapshot, onError: controller.addError);
  }

  final friendsListSub = friendsListStream.listen(onFriendsListChanged, onError: controller.addError);

  controller.onCancel = () {
    visibleSub.cancel();
    friendsListSub.cancel();
    friendPostsSub?.cancel();
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
    final userDoc = await _db.collection('users').doc(uid).get();
    final photoUrl = userDoc.data()?['photo_url'] ?? '';

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
      'photo_url': photoUrl,
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

  Stream<List<QueryDocumentSnapshot>> userPostsStream({
  required String viewerUid,
  required String profileUid,
}) {
  final base = _db.collection('posts').where('uid', isEqualTo: profileUid);

  if (viewerUid == profileUid) {
    return base.orderBy('created_at', descending: true).snapshots().map((s) => s.docs);
  }

  // watch the friendship doc itself, so the query swaps live if it changes
  return _db
      .collection('users').doc(viewerUid)
      .collection('friends').doc(profileUid)
      .snapshots()
      .asyncExpand((friendDoc) {
        final isFriend = friendDoc.exists;
        final query = isFriend
            ? base.orderBy('created_at', descending: true)
            : base.where('is_public', isEqualTo: true).orderBy('created_at', descending: true);
        return query.snapshots().map((s) => s.docs);
      });
}
}

