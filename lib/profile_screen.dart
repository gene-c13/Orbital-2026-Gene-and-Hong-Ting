import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

const Color kSurface = Color(0x14FFFFFF);
const Color kBorder  = Color(0x22FFFFFF);
const Color kAccent  = Color(0xFFB14EFF);
const Color kMuted   = Color(0xCCFFFFFF);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedTab = 3;

  // ── Placeholder stats ─────────────────────────────────────────────────
  // TODO: replace with real Firestore data from users/{uid}
  // Fields needed in Firestore: hours_this_month (int), events_this_month (int),
  // puke_count (int), total_events (int), favourite_venue (string),
  // favourite_genre (string), clubs_visited (array of strings)
  final int hoursThisMonth   = 14;
  final int eventsThisMonth  = 5;
  final int pukeCount        = 2;
  final int totalEvents      = 38;
  final String favouriteVenue = 'Fabric';
  final String favouriteGenre = 'Techno';
  final List<String> clubsVisited = [
    'Fabric', 'EGG London', 'XOYO', 'Fold', 'Printworks', 'Junction 2',
  ];
  // ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'Raver';

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) {
          if (index == 3) return;
          if (index == 0) {
            Navigator.of(context).pop();
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${['Events', 'Social', 'Marketplace', 'Profile'][index]} — coming soon!',
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFF1A0A3B),
        selectedItemColor: kAccent,
        unselectedItemColor: kMuted,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.people),         label: 'Social'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag),   label: 'Marketplace'),
          BottomNavigationBarItem(icon: Icon(Icons.person),         label: 'Profile'),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E1065), Color(0xFF5B21B6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Profile',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (!context.mounted) return;
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      icon: const Icon(Icons.logout, color: Colors.white, size: 18),
                      label: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar + name
                      _avatarCard(displayName),
                      const SizedBox(height: 20),

                      // This month
                      _sectionLabel('This month'),
                      const SizedBox(height: 10),
                      _statsRow([
                        _StatItem(label: 'Hours out', value: '$hoursThisMonth h', icon: Icons.nightlife),
                        _StatItem(label: 'Events',    value: '$eventsThisMonth',  icon: Icons.calendar_today),
                        _StatItem(label: 'Puke count', value: '$pukeCount 🤮',    icon: Icons.sick),
                      ]),
                      const SizedBox(height: 20),

                      // All time
                      _sectionLabel('All time'),
                      const SizedBox(height: 10),
                      _statsRow([
                        _StatItem(label: 'Events attended', value: '$totalEvents',    icon: Icons.confirmation_number),
                        _StatItem(label: 'Fave venue',      value: favouriteVenue,    icon: Icons.location_on),
                        _StatItem(label: 'Fave genre',      value: favouriteGenre,    icon: Icons.music_note),
                      ]),
                      const SizedBox(height: 20),

                      // Clubs visited
                      _sectionLabel('Clubs visited'),
                      const SizedBox(height: 10),
                      _clubsCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────

  Widget _avatarCard(String displayName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: kAccent.withOpacity(0.3),
            child: Text(
              displayName[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                FirebaseAuth.instance.currentUser?.email ?? '',
                style: const TextStyle(color: kMuted, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(color: kMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
    );
  }

  Widget _statsRow(List<_StatItem> items) {
    return Row(
      children: items.map((item) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: item == items.last ? 0 : 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, color: kAccent, size: 18),
                const SizedBox(height: 8),
                Text(
                  item.value,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(item.label, style: const TextStyle(color: kMuted, fontSize: 11)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _clubsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: clubsVisited.map((club) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF241B30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.nightlife, color: kAccent, size: 14),
                const SizedBox(width: 6),
                Text(club, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Simple data class for stat tiles
class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  const _StatItem({required this.label, required this.value, required this.icon});
}