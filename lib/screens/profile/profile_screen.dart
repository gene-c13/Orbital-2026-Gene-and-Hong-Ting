import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/screens/auth/login_screen.dart';
import 'package:after_hours/widgets/navigation_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
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
    if (!mounted) return;
    setState(() {
      _userData = doc.exists ? (doc.data() ?? {}) : {};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'Raver';

    return Scaffold(
      bottomNavigationBar: buildNavBar(3, (i) { if (i != 3) goToTab(context, i); }),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: kBgDecoration,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
                child: Row(
                  children: [
                    const Text(
                      'PROFILE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        if (!context.mounted) return;
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.logout, color: kDim, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: kBorder),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: kAccent, strokeWidth: 2))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _avatarCard(displayName),
                            const SizedBox(height: 24),

                            _sectionLabel('This month'),
                            const SizedBox(height: 10),
                            _statsRow([
                              _StatItem(label: 'Hours out',  value: '${((_userData['hours_this_month'] ?? 0) as num).toStringAsFixed(1)}h',  icon: Icons.nightlife),
                              _StatItem(label: 'Events',     value: '${_userData['events_this_month'] ?? 0}',  icon: Icons.calendar_today),
                              _StatItem(label: 'Puke count', value: '${_userData['puke_count'] ?? 0} 🤮',       icon: Icons.sick),
                            ]),
                            const SizedBox(height: 24),

                            _sectionLabel('All time'),
                            const SizedBox(height: 10),
                            _statsRow([
                              _StatItem(label: 'Events',     value: '${_userData['total_events'] ?? 0}',               icon: Icons.confirmation_number),
                              _StatItem(label: 'Fave venue', value: '${_userData['favourite_venue'] ?? '—'}',           icon: Icons.location_on),
                              _StatItem(label: 'Fave genre', value: '${_userData['favourite_genre'] ?? '—'}',           icon: Icons.music_note),
                            ]),
                            const SizedBox(height: 24),

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

  Widget _avatarCard(String displayName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: kAccent.withValues(alpha: 0.25),
            child: Text(
              displayName[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text(
                FirebaseAuth.instance.currentUser?.email ?? '',
                style: const TextStyle(color: kDim, fontSize: 12),
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
      style: const TextStyle(color: kDim, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5),
    );
  }

  Widget _statsRow(List<_StatItem> items) {
    return Row(
      children: items.mapIndexed((i, item) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < items.length - 1 ? 10 : 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, color: kAccent, size: 16),
                const SizedBox(height: 8),
                Text(item.value,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(item.label, style: const TextStyle(color: kDim, fontSize: 10, letterSpacing: 0.2)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _clubsCard() {
    final clubs = _userData['clubs_visited'] as List<dynamic>? ?? [];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: clubs.isEmpty
          ? const Text('No clubs logged yet.', style: TextStyle(color: kDim, fontSize: 13))
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: clubs.map((club) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0x22B14EFF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: kBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.nightlife, color: kAccent, size: 13),
                      const SizedBox(width: 6),
                      Text(club, style: const TextStyle(color: Colors.white, fontSize: 12)),
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

extension<T> on List<T> {
  Iterable<R> mapIndexed<R>(R Function(int index, T item) f) sync* {
    for (var i = 0; i < length; i++) {
      yield f(i, this[i]);
    }
  }
}
