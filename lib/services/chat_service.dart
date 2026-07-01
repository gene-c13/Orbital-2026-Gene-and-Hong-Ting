import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;

  // Generates a consistent chat ID for two users regardless of who initiates.
  // Sorting the UIDs means uid1_uid2 and uid2_uid1 always produce the same string.
  String _chatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<String> getOrCreateChat(String currentUid, String otherUid) async {
    final chatId = _chatId(currentUid, otherUid);
    final ref = _db.collection('chats').doc(chatId);
    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        'participants':      [currentUid, otherUid],
        'last_message':      '',
        'last_message_time': FieldValue.serverTimestamp(),
        'created_at':        FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }

  Future<void> sendMessage(String chatId, String senderUid, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final chatRef = _db.collection('chats').doc(chatId);

    await chatRef.collection('messages').add({
      'sender_uid': senderUid,
      'text':       trimmed,
      'created_at': FieldValue.serverTimestamp(),
    });

    await chatRef.update({
      'last_message':      trimmed,
      'last_message_time': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> messagesStream(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('created_at', descending: false)
        .snapshots();
  }

  Stream<QuerySnapshot> userChatsStream(String uid) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('last_message_time', descending: true)
        .snapshots();
  }
}