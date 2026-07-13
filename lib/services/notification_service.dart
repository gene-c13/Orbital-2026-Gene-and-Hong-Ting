import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:after_hours/models/notification_item.dart';

class NotificationService {
  // singleton — every NotificationService() call returns the same instance,
  // so the _cache below is actually shared across the whole app instead of
  // starting fresh each time someone writes NotificationService() again
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final _db = FirebaseFirestore.instance;

  // one shared stream per uid. As long as at least one widget is still
  // listening, this stays alive and everyone else piggybacks on it.
  final Map<String, Stream<List<NotificationItem>>> _cache = {};

  // the most recent merged result per uid — lets a NEW subscriber (like a
  // panel you just opened) see the current state immediately instead of
  // waiting for the next Firestore change, since broadcast streams never
  // replay past events to listeners who joined late.
  final Map<String, List<NotificationItem>> _latestValues = {};

  List<NotificationItem>? latestFor(String uid) => _latestValues[uid];

  Stream<List<NotificationItem>> notificationsStream(String uid) {
    return _cache.putIfAbsent(uid, () => _buildStream(uid));
  }

  Stream<List<NotificationItem>> _buildStream(String uid) {
    final requestsStream = _db
        .collection('friend_requests')
        .where('to_uid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();

    final chatsStream = _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('last_message_time', descending: true)
        .snapshots();

    List<NotificationItem> latestRequests = [];
    List<NotificationItem> latestMessages = [];

    // each of the 2 sources resolves independently and at a different
    // speed. Without these flags, whichever source happens to answer
    // first would fire the stream's very first emission with the OTHER
    // still empty — a false "everything's empty" snapshot that later
    // gets silently overwritten. Waiting for both means the first
    // real emission is always a complete, accurate picture.
    var requestsReady = false;
    var chatsReady = false;

    List<NotificationItem> merge() {
      final merged = [...latestRequests, ...latestMessages];
      merged.sort((a, b) {
        if (a.timestamp == null && b.timestamp == null) return 0;
        if (a.timestamp == null) return 1;
        if (b.timestamp == null) return -1;
        return b.timestamp!.compareTo(a.timestamp!);
      });
      return merged;
    }

    final controller = StreamController<List<NotificationItem>>.broadcast();

    void emitIfReady() {
      if (!(requestsReady && chatsReady)) return;
      final merged = merge();
      _latestValues[uid] = merged;
      controller.add(merged);
    }

    final requestsSub = requestsStream.listen((snap) {
      latestRequests = snap.docs.map((doc) {
        final data = doc.data();
        return NotificationItem(
          type: NotificationType.friendRequest,
          id: doc.id,
          actorUid: data['from_uid'] as String? ?? '',
          timestamp: data['created_at'] as Timestamp?,
        );
      }).toList();
      requestsReady = true;
      emitIfReady();
    }, onError: controller.addError);

    final chatsSub = chatsStream.listen((snap) {
      latestMessages = snap.docs
          .map((doc) {
            final data = doc.data();
            final lastSender = data['last_sender_uid'] as String?;
            if (lastSender == null || lastSender == uid) return null;

            final participants = List<String>.from(data['participants'] ?? []);
            final otherUid = participants.firstWhere((p) => p != uid, orElse: () => '');
            if (otherUid.isEmpty) return null;

            final lastMessageTime = data['last_message_time'] as Timestamp?;

            return NotificationItem(
              type: NotificationType.message,
              // was: id: doc.id (the chat's id — same for every message in
              // the conversation, so only the FIRST text from someone ever
              // registered as "new"). Folding the timestamp in means each
              // new message actually produces a new id.
              id: '${doc.id}_${lastMessageTime?.millisecondsSinceEpoch ?? 0}',
              actorUid: otherUid,
              preview: data['last_message'] as String? ?? '',
              timestamp: lastMessageTime,
            );
          })
          .whereType<NotificationItem>()
          .toList();
      chatsReady = true;
      emitIfReady();
    }, onError: controller.addError);

    controller.onCancel = () {
      // fires only once the LAST listener has unsubscribed (broadcast
      // streams count subscribers) — safe to tear everything down
      requestsSub.cancel();
      chatsSub.cancel();
      controller.close();
      _cache.remove(uid); // so the next call builds a fresh stream, not a dead one
      _latestValues.remove(uid);
    };

    return controller.stream;
  }

  Future<void> markSeen(String uid) async {
    await _db.collection('users').doc(uid).set(
      {'notifications_seen_at': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }
}