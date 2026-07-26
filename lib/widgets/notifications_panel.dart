import 'package:flutter/material.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/models/notification_item.dart';
import 'package:after_hours/models/user.dart';
import 'package:after_hours/services/notification_service.dart';
import 'package:after_hours/services/user_service.dart';
import 'package:after_hours/services/auth_service.dart';
import 'package:after_hours/utils/time_format.dart';
import 'package:after_hours/widgets/navigation_helper.dart';
import 'package:after_hours/screens/social/friend_requests_screen.dart';

class NotificationsPanel extends StatefulWidget {
  const NotificationsPanel({super.key});

  @override
  State<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<NotificationsPanel> {
  @override
  void initState() {
    super.initState();
    // opening the panel counts as "seen":  clears the bell's dot next time
    final uid = AuthService().currentUid;
    if (uid != null) NotificationService().markSeen(uid);
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUid ?? '';

    return Container(
      decoration: const BoxDecoration(
        color: kSheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Text('NOTIFICATIONS', style: kNectarine(size: 20, letterSpacing: 3)),
                ],
              ),
            ),
            const Divider(height: 1, color: kBorder),
            Flexible(
              child: StreamBuilder<List<NotificationItem>>(
                stream: NotificationService().notificationsStream(uid),
                // same reasoning as the bell: start with the shared
                // stream's current value instead of waiting for the next
                // Firestore change to arrive
                initialData: NotificationService().latestFor(uid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator(color: kAccent, strokeWidth: 2)),
                    );
                  }

                  final items = snapshot.data!;
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('No notifications yet', style: TextStyle(color: kDim))),
                    );
                  }

                  // friend_request and message items only carry a uid, not a
                  // name: batch-fetch every actor once, same pattern as
                  // FriendRequestsScreen, instead of one read per row.
                  final uidsNeedingLookup = items
                      .map((i) => i.actorUid)
                      .toSet()
                      .toList();

                  return FutureBuilder<List<AppUser>>(
                    future: UserService().getUsers(uidsNeedingLookup),
                    builder: (context, usersSnap) {
                      final usersByUid = <String, AppUser>{
                        for (final u in usersSnap.data ?? <AppUser>[]) u.uid: u,
                      };

                      return ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final name = usersByUid[item.actorUid]?.name ?? 'Someone';
                          return _NotificationRow(item: item, name: name);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final NotificationItem item;
  final String name;

  const _NotificationRow({required this.item, required this.name});

  IconData get _icon {
    switch (item.type) {
      case NotificationType.friendRequest:
        return Icons.person_add_alt;
      case NotificationType.message:
        return Icons.chat_bubble_outline;
    }
  }

  String get _text {
    switch (item.type) {
      case NotificationType.friendRequest:
        return '$name sent you a friend request';
      case NotificationType.message:
        return '$name: ${item.preview}';
    }
  }

  void _onTap(BuildContext context) {
    Navigator.of(context).pop(); // close the panel first
    switch (item.type) {
      case NotificationType.friendRequest:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FriendRequestsScreen()),
        );
        break;
      case NotificationType.message:
        openChat(context, item.actorUid, name);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_icon, color: kAccent, size: 22),
      title: Text(
        _text,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: item.timestamp != null
          ? Text(timeAgo(item.timestamp), style: const TextStyle(color: kDim, fontSize: 11))
          : null,
      onTap: () => _onTap(context),
    );
  }
}