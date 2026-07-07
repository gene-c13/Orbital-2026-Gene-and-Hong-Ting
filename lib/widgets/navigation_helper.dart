import 'dart:async';
import 'package:after_hours/screens/chat/chat_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:after_hours/screens/events/events_screen.dart';
import 'package:after_hours/screens/social/social_screen.dart';
import 'package:after_hours/screens/profile/profile_screen.dart';
import 'package:after_hours/screens/auth/login_screen.dart';

void goToTab(BuildContext context, int targetIndex) {

  Widget screen;
  if (targetIndex == 1) {
    screen = const SocialScreen();
  } else if (targetIndex == 2) {
    screen = const ChatListScreen();
  } else if (targetIndex == 3) {
    screen = const ProfileScreen();
  } else {
    screen = const EventsScreen();
  }

  // Clear the whole stack and push the new tab — no stacking.
  // Each tab is wrapped in _AuthGuard so remote session revocation
  // (account deleted, token revoked) still redirects to login even
  // though the auth gate in main.dart was removed from the tree.
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => _AuthGuard(child: screen)),
    (route) => false,
  );
}

// Wraps a tab screen and listens to auth state. If the session is
// revoked while the tab is active, it navigates straight to login.
class _AuthGuard extends StatefulWidget {
  final Widget child;
  const _AuthGuard({required this.child});

  @override
  State<_AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<_AuthGuard> {
  late final StreamSubscription<User?> _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}