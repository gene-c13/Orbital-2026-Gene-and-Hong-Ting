import 'package:flutter_test/flutter_test.dart';
import 'package:after_hours/models/notification_item.dart';

// NotificationItem has no fromFirestore() or parsing logic of its own -
// that lives in NotificationService, which needs the Firebase emulator to
// test properly (see the integration test plan). All there is to check
// here is the constructor's one default value.

void main() {
  test('preview defaults to an empty string when not provided', () {
    const item = NotificationItem(
      type: NotificationType.friendRequest,
      id: 'n1',
      actorUid: 'u1',
      timestamp: null,
    );

    expect(item.preview, '');
  });
}
