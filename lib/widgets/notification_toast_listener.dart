import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:after_hours/models/notification_item.dart';
import 'package:after_hours/services/notification_service.dart';
import 'package:after_hours/services/user_service.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/widgets/navigation_helper.dart';
import 'package:after_hours/screens/social/friend_requests_screen.dart';

//wraps the whole app, watches for new notifications on the signed in uid
//and drops a banner at the top. tapping it opens the request or the chat
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
      //switching accounts or signing out wipes the old state so the next
      //user doesn't inherit what the previous one had already seen
      _notifSub?.cancel();
      _knownIds = {};
      _isFirstLoad = true;
      if (user == null) return;

      //bell or panel may have subscribed first and eaten the first snapshot,
      //so use their cached copy as our baseline if there is one
      final cached = NotificationService().latestFor(user.uid);
      if (cached != null) {
        _knownIds = cached.map((i) => i.id).toSet();
        _isFirstLoad = false;
      }

      _notifSub = NotificationService().notificationsStream(user.uid).listen((items) {
        final currentIds = items.map((i) => i.id).toSet();

        if (_isFirstLoad) {
          //only show banners for stuff that arrives while the app is open
          _knownIds = currentIds;
          _isFirstLoad = false;
          return;
        }

        //.toList() runs the filter now, before the next line swaps _knownIds.
        //without it .where() stays lazy and only checks when the loop reads it,
        //by which point _knownIds is the new set and nothing looks new
        final newItems = items.where((i) => !_knownIds.contains(i.id)).toList();
        _knownIds = currentIds;

        for (final item in newItems) {
          if (item.actorUid == user.uid) continue; //never toast your own actions
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

    //using the Overlay instead of a SnackBar because it sits above every
    //screen and dialog, so the banner shows no matter what's on screen
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

  //same destinations as tapping a row in the notifications panel. uses the
  //root navigator since a toast can show up over any screen
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

//the banner itself. slides down from the top, waits 3 seconds, then slides
//back up and removes itself
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
    //Positioned, works without our own Stack because Overlay already puts
    //every entry inside one (Positioned must be inside a Stack)
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
              //no point animating the banner out when a new screen is about to cover it
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