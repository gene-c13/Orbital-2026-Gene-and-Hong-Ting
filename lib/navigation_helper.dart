import 'package:flutter/material.dart';
import 'events_screen.dart';
import 'social_screen.dart';
import 'profile_screen.dart';

void goToTab(BuildContext context, int targetIndex) {
  if (targetIndex == 2) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marketplace — coming soon!')),
    );
    return;
  }

  final Widget screen = switch (targetIndex) {
    0 => const EventsScreen(),
    1 => const SocialScreen(),
    3 => const ProfileScreen(),
    _ => const EventsScreen(),
  };

  // Clear the whole stack and push the new tab — no stacking
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => screen),
    (route) => false,
  );
}