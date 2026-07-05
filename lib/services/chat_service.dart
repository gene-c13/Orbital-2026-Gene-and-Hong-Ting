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
    // merge:true means two devices opening the same new chat simultaneously
    // both write the same doc without clobbering last_message or last_message_time
    await ref.set({
      'participants': [currentUid, otherUid],
      'created_at':  FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return chatId; //screen uses chatID to load messages or send new ones
  }

  Future<void> sendMessage(String chatId, String senderUid, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return; //not allowed to send blank messages

    final chatRef = _db.collection('chats').doc(chatId);

    final batch = _db.batch(); //refer to comments_sheet.dart for syntax explanantion
    batch.set(chatRef.collection('messages').doc(), { //set a document in the 'messages' subcollection of the doc(ChatID)
      'sender_uid': senderUid,
      'text':       trimmed,
      'created_at': FieldValue.serverTimestamp(),
    });
    batch.update(chatRef, { //queue second write that updates the chat document's preview fields
      'last_message':      trimmed,
      'last_message_time': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Stream<QuerySnapshot> messagesStream(String chatId) { //stream messages in real time
    return _db
        .collection('chats') //querysnapshot is a container holding documents that match the query (like a question and answer)
        .doc(chatId)
        .collection('messages')
        .orderBy('created_at', descending: false) //this is the query
        .snapshots();  //asks for documents that match the query, this also creates the stream
  } // if u wanted a one time fetch and not stream, use .get instead of .snapshots

  Stream<QuerySnapshot> userChatsStream(String uid) { //returns a live list of every conversation the user is part of
    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('last_message_time', descending: true)
        .snapshots();
  }
}