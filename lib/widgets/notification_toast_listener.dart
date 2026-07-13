import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:after_hours/models/notification_item.dart';
import 'package:after_hours/services/notification_service.dart';
import 'package:after_hours/services/user_service.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/widgets/navigation_helper.dart';
import 'package:after_hours/screens/social/friend_requests_screen.dart';

/// Wraps the whole app. Watches notificationsStream for whichever uid is
/// currently signed in, and pops up a banner the instant something new
/// shows up — a friend request or a message. Tapping the banner takes you
/// straight to the relevant screen, same as tapping the row in the panel.
class NotificationToastListener extends StatefulWidget {
  final Widget child;
  const NotificationToastListener({super.key, required this.child});

  @override
  State<NotificationToastListener> createState() => _NotificationToastListenerState();
}

class _NotificationToastListenerState extends State<NotificationToastListener> {
  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<NotificationItem>>? _notifSub;
  Set<String> _knownIds = {};
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      // switching accounts (or signing out) resets what "known" means
      _notifSub?.cancel();
      _knownIds = {};
      _isFirstLoad = true;
      if (user == null) return;

      // the bell or panel may already be subscribed to this uid's shared
      // stream and have consumed the real "already existed" snapshot before
      // we get here — broadcast streams don't replay it to late joiners. If
      // that already happened, grab their cached result as our baseline
      // instead of waiting for the next Firestore event and mistaking a
      // real new item for "stuff that was already there".
      final cached = NotificationService().latestFor(user.uid);
      if (cached != null) {
        _knownIds = cached.map((i) => i.id).toSet();
        _isFirstLoad = false;
      }

      _notifSub = NotificationService().notificationsStream(user.uid).listen((items) {
        final currentIds = items.map((i) => i.id).toSet();

        if (_isFirstLoad) {
          // the very first emission is everything that already existed
          // before you opened the app — not "new", so don't toast for it
          _knownIds = currentIds;
          _isFirstLoad = false;
          return;
        }

        // .toList() forces this to run right now, while _knownIds still
        // holds the OLD set — without it, the check below would silently
        // re-run later against the reassigned _knownIds (since a bare
        // .where() re-checks its condition every time it's looped over)
        // and find zero "new" items every time.
        final newItems = items.where((i) => !_knownIds.contains(i.id)).toList();
        _knownIds = currentIds;

        for (final item in newItems) {
          if (item.actorUid == user.uid) continue; // never toast your own actions
          _showToast(item);
        }
      });
    });
  }

  Future<void> _showToast(NotificationItem item) async {
    final actor = await UserService().getUser(item.actorUid);
    final name = actor?.name ?? 'Someone';

    final text = switch (item.type) {
      NotificationType.friendRequest => '$name has sent you a friend request',
      NotificationType.message       => '$name: ${item.preview}',
    };

    // insert straight into the app's Overlay instead of using a
    // SnackBar/ScaffoldMessenger — the Overlay sits above every screen,
    // dialog, and route in the app, so this shows up no matter what's
    // currently on screen, always pinned to the top.
    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastBanner(
        text: text,
        onDismiss: () => entry.remove(),
        onTap: () {
          entry.remove();
          _openNotification(item, name);
        },
      ),
    );
    overlayState.insert(entry);
  }

  // Same destinations as tapping a row in the notifications panel — takes
  // whatever the current route stack is and pushes the relevant screen
  // on top, using the root navigator since a toast can appear over anything.
  void _openNotification(NotificationItem item, String name) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
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
  void dispose() {
    _authSub?.cancel();
    _notifSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// The visible banner itself. Slides down from above the screen, sits for
// a few seconds, then slides back up and removes itself from the Overlay.
class _ToastBanner extends StatefulWidget {
  final String text;
  final VoidCallback onDismiss;
  final VoidCallback onTap;
  const _ToastBanner({required this.text, required this.onDismiss, required this.onTap});

  @override
  State<_ToastBanner> createState() => _ToastBannerState();
}

class _ToastBannerState extends State<_ToastBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _slide = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      await _controller.reverse();
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Positioned works here without wrapping in a Stack ourselves —
    // Overlay already renders every OverlayEntry inside its own Stack.
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              // tapping navigates straight away — no point animating the
              // banner out first when a whole new screen is about to cover it
              onTap: widget.onTap,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: kSheet,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kBorder),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications, color: kAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.text,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}