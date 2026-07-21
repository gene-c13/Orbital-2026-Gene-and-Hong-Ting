import 'package:flutter_test/flutter_test.dart';
import 'package:after_hours/utils/chat_id.dart';

// chatId() used to be a private method inside ChatService, which meant it
// couldn't be tested without a live Firestore connection. Now it's a pure
// function in lib/utils/chat_id.dart, so we can call it directly.

void main() {
  test('gives the same id no matter which user is passed first', () {
    expect(chatId('uidA', 'uidB'), chatId('uidB', 'uidA'));
  });

  test('is stable across repeated calls with the same uids', () {
    final first = chatId('uidA', 'uidB');
    final second = chatId('uidA', 'uidB');
    expect(first, second);
  });

  test('combines both uids into the id', () {
    final id = chatId('uidA', 'uidB');
    expect(id, contains('uidA'));
    expect(id, contains('uidB'));
  });
}
