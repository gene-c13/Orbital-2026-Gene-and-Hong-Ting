import 'package:cloud_firestore/cloud_firestore.dart';

class PostService {
  final _db = FirebaseFirestore.instance;

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
}
