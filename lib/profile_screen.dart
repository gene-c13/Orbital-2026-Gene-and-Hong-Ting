import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      setState(() => _userData = doc.data() ?? {});
    }
  }
  

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
                        _StatItem(label: 'Hours out', value: '${_userData['hours_this_month'] ?? 0} h', icon: Icons.nightlife),
                        _StatItem(label: 'Events',    value: '${_userData['events_this_month'] ?? 0}',  icon: Icons.calendar_today),
                        _StatItem(label: 'Puke count', value: '${_userData['puke_count'] ?? 0} 🤮',    icon: Icons.sick),
                      ]),
                      const SizedBox(height: 20),

                      // All time
                      _sectionLabel('All time'),
                      const SizedBox(height: 10),
                      _statsRow([
                       _StatItem(label: 'Events attended', value: '${_userData['total_events'] ?? 0}',        icon: Icons.confirmation_number),
                       _StatItem(label: 'Fave venue',      value: '${_userData['favourite_venue'] ?? 'TBC'}', icon: Icons.location_on),
                       _StatItem(label: 'Fave genre',      value: '${_userData['favourite_genre'] ?? 'TBC'}', icon: Icons.music_note),
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
        children: (_userData['clubs_visited'] as List<dynamic>? ?? []).map((club) {
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