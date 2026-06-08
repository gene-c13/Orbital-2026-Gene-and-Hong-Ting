import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'navigation_helper.dart';

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
  bool _loading = true;

  // Stats — null until loaded from Firestore
  int hoursThisMonth  = 0;
  int eventsThisMonth = 0;
  int pukeCount       = 0;
  int totalEvents     = 0;
  String favouriteVenue = '—';
  String favouriteGenre = '—';
  List<String> clubsVisited = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!mounted) return;

    final data = doc.data() ?? {};
    setState(() {
      hoursThisMonth  = (data['hours_this_month']  ?? 0) as int;
      eventsThisMonth = (data['events_this_month'] ?? 0) as int;
      pukeCount       = (data['puke_count']        ?? 0) as int;
      totalEvents     = (data['total_events']      ?? 0) as int;
      favouriteVenue  = (data['favourite_venue']   ?? '—') as String;
      favouriteGenre  = (data['favourite_genre']   ?? '—') as String;
      clubsVisited    = List<String>.from(data['clubs_visited'] ?? []);
      _loading        = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'Raver';

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: (index) {
          if (index == 3) return; // already here
          goToTab(context, index);
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
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
                child: Row(
                  children: [
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

              // Body
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _avatarCard(displayName),
                            const SizedBox(height: 20),

                            _sectionLabel('This month'),
                            const SizedBox(height: 10),
                            _statsRow([
                              _StatItem(label: 'Hours out',   value: '$hoursThisMonth h',  icon: Icons.nightlife),
                              _StatItem(label: 'Events',      value: '$eventsThisMonth',   icon: Icons.calendar_today),
                              _StatItem(label: 'Puke count',  value: '$pukeCount 🤮',      icon: Icons.sick),
                            ]),
                            const SizedBox(height: 20),

                            _sectionLabel('All time'),
                            const SizedBox(height: 10),
                            _statsRow([
                              _StatItem(label: 'Events attended', value: '$totalEvents',   icon: Icons.confirmation_number),
                              _StatItem(label: 'Fave venue',      value: favouriteVenue,   icon: Icons.location_on),
                              _StatItem(label: 'Fave genre',      value: favouriteGenre,   icon: Icons.music_note),
                            ]),
                            const SizedBox(height: 20),

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
            backgroundColor: kAccent.withValues(alpha: 0.3),
            child: Text(
              displayName[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(FirebaseAuth.instance.currentUser?.email ?? '',
                  style: const TextStyle(color: kMuted, fontSize: 13)),
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
                Text(item.value,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
    if (clubsVisited.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: const Text('No clubs logged yet.', style: TextStyle(color: kMuted, fontSize: 14)),
      );
    }

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

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  const _StatItem({required this.label, required this.value, required this.icon});
}