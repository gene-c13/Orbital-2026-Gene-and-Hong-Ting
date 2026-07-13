import 'package:flutter/material.dart';
// Lets code outside the widget tree (like NotificationToastListener) show a
// SnackBar without needing a local BuildContext from whatever screen
// happens to be on top right now.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

// Gives access to the app's single Overlay from outside the widget tree —
// used to insert the top-of-screen notification banner on top of whatever
// screen or dialog is currently showing, regardless of which one that is.
final navigatorKey = GlobalKey<NavigatorState>();

// ── Palette ───────────────────────────────────────────────────────────────────
const Color kBg      = Color(0xFF070010);
const Color kBgMid   = Color(0xFF160333);
const Color kNavBg   = Color(0xFF060010);
const Color kSurface = Color(0x1AFFFFFF);
const Color kBorder  = Color(0x1AFFFFFF);
const Color kAccent  = Color(0xFFB14EFF);
const Color kPink    = Color(0xFFFF2D95);
const Color kMuted   = Color(0xCCFFFFFF);
const Color kDim     = Color(0x80FFFFFF);
const Color kTransparentPink = Color(0x26FF2D95);

// ── Typography ────────────────────────────────────────────────────────────────
const kFontNectarine = 'Nectarine';

TextStyle kNectarine({double size = 32, Color color = Colors.white, double? letterSpacing}) {
  return TextStyle(
    fontFamily: kFontNectarine,
    fontSize: size,
    color: color,
    letterSpacing: letterSpacing ?? size * 0.02,
  );
}

// ── Backgrounds ───────────────────────────────────────────────────────────────
const kBgDecoration = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [kBg, kBgMid],
  ),
);

const kBgDecorationAuth = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F0420), Color(0xFF2B0B3A), Color(0xFF1A0533)],
  ),
);

// ── Shared gradient button decoration ────────────────────────────────────────
const kPrimaryButtonDecoration = BoxDecoration(
  gradient: LinearGradient(colors: [kAccent, kPink]),
  borderRadius: BorderRadius.all(Radius.circular(14)),
  boxShadow: [BoxShadow(color: Color(0x66FF2D95), blurRadius: 24, spreadRadius: 1)],
);

// ── Surface card (posts, event cards, profile sections, etc.) ─────────────────
const kCardDecoration = BoxDecoration(
  color: kSurface,
  borderRadius: BorderRadius.all(Radius.circular(16)),
  border: Border.fromBorderSide(BorderSide(color: kBorder)),
);

// ── Bottom sheet background colour ───────────────────────────────────────────
const Color kSheet = Color(0xFF130228);

// ── Music genres list ─────────────────────────────────────────────────────────
const kGenres = <String>[
  'House', 'Techno', 'Drum & Bass', 'Hip-Hop', 'R&B',
  'Afrobeats', 'Garage', 'Trance', 'Disco', 'Jungle',
  'Dubstep', 'Pop', 'Reggaeton', 'Latin', 'Other',
];

// ── Crowd level colour (shared by event cards and event detail) ──────────────
Color crowdColor(String level) {
  if (level == 'High')   return const Color(0xFFFF6B3D);
  if (level == 'Medium') return const Color(0xFFE0C040);
  return const Color(0xFF4CAF50);
}

// ── Bottom nav ────────────────────────────────────────────────────────────────
const kNavItems = <BottomNavigationBarItem>[
  BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Events'),
  BottomNavigationBarItem(icon: Icon(Icons.people),         label: 'Social'),
  BottomNavigationBarItem(icon: Icon(Icons.chat_bubble),   label: 'Chats'),
  BottomNavigationBarItem(icon: Icon(Icons.person),         label: 'Profile'),
];

BottomNavigationBar buildNavBar(int currentIndex, void Function(int) onTap) {
  return BottomNavigationBar(
    currentIndex: currentIndex,
    onTap: onTap,
    backgroundColor: kNavBg,
    selectedItemColor: kAccent,
    unselectedItemColor: kDim,
    type: BottomNavigationBarType.fixed,
    selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    unselectedLabelStyle: const TextStyle(fontSize: 11),
    items: kNavItems,
  );
}
