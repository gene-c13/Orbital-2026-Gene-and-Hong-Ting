import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/screens/auth/login_screen.dart';
import 'package:after_hours/widgets/navigation_helper.dart';
import 'package:after_hours/services/friend_service.dart';
import 'package:after_hours/services/user_service.dart';
import 'package:after_hours/screens/chat/chat_list_screen.dart';
import 'package:after_hours/screens/profile/edit_profile_sheet.dart';

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
  final data = await UserService().fetchUserData(user.uid);
  if (!mounted) return;
  setState(() {
    _userData = data;
    _loading = false;
  });
}

  void _openEditPopup() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final displayName = user.displayName ?? user.email?.split('@').first ?? 'Raver';
    final genre    = _userData['favourite_genre'] as String?;
    final venue    = _userData['favourite_venue'] as String?;
    final photoUrl = _userData['photo_url'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(
        initialName:     displayName,
        username:        _userData['username'] as String? ?? '',
        initialVenue:    venue    ?? '',
        initialGenre:    (genre?.isEmpty    ?? true) ? null : genre,
        initialPhotoUrl: (photoUrl?.isEmpty ?? true) ? null : photoUrl,
        initialIsPublic: _userData['is_public'] as bool? ?? true,
        uid:             user.uid,
        onSaved:         _loadUserData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user        = FirebaseAuth.instance.currentUser;
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
                    Text('PROFILE', style: kNectarine(size: 28, letterSpacing: 4)),
                    const Spacer(),
                    GestureDetector(
                      onTap: _openEditPopup,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.edit_outlined, color: kDim, size: 20),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ChatListScreen()),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.chat_bubble_outline, color: kDim, size: 20),
                      ),
                    ),
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
                            _friendRequestsSection(user?.uid ?? ''),
                            _avatarCard(displayName),
                            const SizedBox(height: 24),

                            _sectionLabel('This month'),
                            const SizedBox(height: 10),
                            _statsRow([
                              _StatItem(label: 'Hours out',  value: '${((_userData['hours_this_month'] ?? 0) as num).toStringAsFixed(1)}h', icon: Icons.nightlife),
                              _StatItem(label: 'Events',     value: '${_userData['events_this_month'] ?? 0}',                               icon: Icons.calendar_today),
                              _StatItem(label: 'Puke count', value: '${_userData['puke_count'] ?? 0} 🤮',                                    icon: Icons.sick),
                            ]),
                            const SizedBox(height: 24),

                            _sectionLabel('All time'),
                            const SizedBox(height: 10),
                            _statsRow([
                              _StatItem(label: 'Events',     value: '${_userData['total_events'] ?? 0}',         icon: Icons.confirmation_number),
                              _StatItem(label: 'Fave venue', value: '${_userData['favourite_venue'] ?? '—'}',     icon: Icons.location_on),
                              _StatItem(label: 'Fave genre', value: '${_userData['favourite_genre'] ?? '—'}',     icon: Icons.music_note),
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

  Widget _friendRequestsSection(String currentUid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FriendService().incomingRequests(currentUid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final requests = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            _sectionLabel('Friend requests'),
            const SizedBox(height: 10),
            ...requests.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final fromUid = data['from_uid'] as String;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(fromUid).get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox.shrink();
                  final userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
                  final username = userData['username'] as String? ?? 'Unknown';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: kAccent.withValues(alpha: 0.3),
                          child: Text(
                            username[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            username,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await FriendService().rejectRequest(doc.id);
                          },
                          child: const Text('Decline', style: TextStyle(color: kMuted)),
                        ),
                        TextButton(
                          onPressed: () async {
                            await FriendService().acceptRequest(doc.id, fromUid, currentUid);
                          },
                          child: const Text('Accept', style: TextStyle(color: kAccent, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
            const SizedBox(height: 14),
          ],
        );
      },
    );
  }

  Widget _avatarCard(String displayName) {
    final photoUrl = _userData['photo_url'] as String?;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

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
            backgroundImage: hasPhoto ? CachedNetworkImageProvider(photoUrl) : null,
            child: hasPhoto
                ? null
                : Text(
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
                _userData['username'] != null ? '@${_userData['username']}' : '',
                style: const TextStyle(color: kMuted, fontSize: 13, fontWeight: FontWeight.w600),
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

// ── Supporting types ──────────────────────────────────────────────────────────

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

