import 'package:flutter/material.dart';

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

// ── Bottom nav ────────────────────────────────────────────────────────────────
const kNavItems = <BottomNavigationBarItem>[
  BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Events'),
  BottomNavigationBarItem(icon: Icon(Icons.people),         label: 'Social'),
  BottomNavigationBarItem(icon: Icon(Icons.shopping_bag),   label: 'Marketplace'),
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
