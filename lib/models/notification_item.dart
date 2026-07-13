import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { friendRequest, message }

// One unified shape for two completely different Firestore documents
// (a friend_request and a chat), so the panel can render them all
// through one list without caring which type it's looking at.
class NotificationItem {
  final NotificationType type;
  final String id;
  final String actorUid;
  final String preview; // message text, empty for a friend request
  final Timestamp? timestamp;

  const NotificationItem({
    required this.type,
    required this.id,
    required this.actorUid,
    this.preview = '',
    required this.timestamp,
  });
}