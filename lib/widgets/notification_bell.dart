import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:after_hours/models/notification_item.dart';
import 'package:after_hours/models/user.dart';
import 'package:after_hours/services/auth_service.dart';
import 'package:after_hours/services/notification_service.dart';
import 'package:after_hours/services/user_service.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/widgets/notifications_panel.dart';

//bell icon in the social screen header. shows a small dot when theres a
//notification newer than notifications_seen_at
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  bool _hasUnseen(List<NotificationItem> items, Timestamp? seenAt) {
    return items.any((item) =>
        item.timestamp != null &&
        (seenAt == null || item.timestamp!.compareTo(seenAt) > 0));
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUid ?? '';

    return StreamBuilder<AppUser?>(
      stream: UserService().userStream(uid),
      builder: (context, userSnap) {
        final seenAt = userSnap.data?.notificationsSeenAt;

        return StreamBuilder<List<NotificationItem>>(
          stream: NotificationService().notificationsStream(uid),
          // the stream is shared/cached, if this bell subscribes after
          // some other widget already started it, it won't see past
          // events on its own, so start it with whatever's already known
          initialData: NotificationService().latestFor(uid),
          builder: (context, notifSnap) {
            final items = notifSnap.data ?? [];
            final hasUnseen = _hasUnseen(items, seenAt);

            return IconButton(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const NotificationsPanel(),
              ),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none, color: Colors.white, size: 22),
                  if (hasUnseen)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(color: kPink, shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}