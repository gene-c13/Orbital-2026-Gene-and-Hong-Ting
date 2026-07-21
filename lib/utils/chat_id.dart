// A consistent chat ID for two users, regardless of who started the chat.
// Sorting the uids means chatId(a, b) and chatId(b, a) always match.
String chatId(String uid1, String uid2) {
  final sorted = [uid1, uid2]..sort();
  return '${sorted[0]}_${sorted[1]}';
}
