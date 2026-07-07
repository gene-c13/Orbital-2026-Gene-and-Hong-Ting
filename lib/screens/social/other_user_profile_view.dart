import 'package:flutter/material.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/services/auth_service.dart';
import 'package:after_hours/services/user_service.dart';
import 'package:after_hours/services/friend_service.dart';
import 'package:after_hours/services/chat_service.dart';
import 'package:after_hours/models/user.dart';
import 'package:after_hours/widgets/user_avatar.dart';
import 'package:after_hours/screens/chat/chat_screen.dart';

// Read-only profile view for someone who ISN'T the signed-in user.
// Opened from things like the comments sheet, where you tap another
// person's name/avatar and want to see who they are.
class OtherUserProfileView extends StatefulWidget {
  final String uid;
  const OtherUserProfileView({super.key, required this.uid});

  @override
  State<OtherUserProfileView> createState() => _OtherUserProfileViewState();
}

class _OtherUserProfileViewState extends State<OtherUserProfileView> {
  final _friendService = FriendService();
  bool _requestSent = false;

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthService().currentUid ?? '';
    final isOwnProfile = currentUid == widget.uid;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: kBgDecoration,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text('PROFILE', style: kNectarine(size: 22, letterSpacing: 3)),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: kBorder),
              Expanded(
                child: StreamBuilder<AppUser?>(
                  stream: UserService().userStream(widget.uid),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: kAccent, strokeWidth: 2));
                    }

                    final appUser = snapshot.data;
                    if (appUser == null) {
                      return const Center(
                        child: Text('User not found.', style: TextStyle(color: kDim)),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _avatarCard(appUser),
                          const SizedBox(height: 16),
                          if (!isOwnProfile) _actionRow(currentUid, appUser),
                          if (!isOwnProfile) const SizedBox(height: 24),
                          _sectionLabel('All time'),
                          const SizedBox(height: 10),
                          _statsRow(appUser),
                          const SizedBox(height: 24),
                          _sectionLabel('Clubs visited'),
                          const SizedBox(height: 10),
                          _clubsCard(appUser.clubsVisited),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarCard(AppUser appUser) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          UserAvatar(photoUrl: appUser.photoUrl, displayName: appUser.name, radius: 30, fontSize: 26),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(appUser.name,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 3),
              Text('@${appUser.username}',
                  style: const TextStyle(color: kMuted, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  // Add / Sent / Message button, same rules as the user search screen:
  // no relationship yet -> Add, request pending -> Sent, already friends -> Message.
  Widget _actionRow(String currentUid, AppUser appUser) {
    return FutureBuilder<List<bool>>(
      future: Future.wait([
        _friendService.isFriend(currentUid, appUser.uid),
        _friendService.hasPendingRequest(currentUid, appUser.uid),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final alreadyFriend = snapshot.data![0];
        final pending = snapshot.data![1] || _requestSent;

        if (alreadyFriend) {
          return Column(
            children: [
              _fullWidthButton('Message', () async {
                await ChatService().getOrCreateChat(currentUid, appUser.uid);
                if (!context.mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(otherUid: appUser.uid, otherDisplayName: appUser.name),
                  ),
                );
              }),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: kSheet,
                      title: const Text('Unfriend?', style: TextStyle(color: Colors.white)),
                      content: Text(
                        'You and ${appUser.name} will no longer be friends.',
                        style: const TextStyle(color: kDim),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Unfriend', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await _friendService.unfriend(currentUid, appUser.uid);
                    if (mounted) setState(() {});
                  }
                },
                child: const Text('Unfriend', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          );
        }

        if (pending) {
          return const Text('Friend request sent', style: TextStyle(color: kMuted, fontWeight: FontWeight.w600));
        }

        return _fullWidthButton('Add friend', () async {
          await _friendService.sendFriendRequest(currentUid, appUser.uid);
          setState(() => _requestSent = true);
        });
      },
    );
  }

  Widget _fullWidthButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: kAccent),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(color: kAccent, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(color: kDim, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5),
    );
  }

  Widget _statsRow(AppUser appUser) {
    final items = [
      _StatItem(label: 'Events', value: '${appUser.totalEvents}', icon: Icons.confirmation_number),
      _StatItem(
        label: 'Fave venue',
        value: appUser.favouriteVenue.isEmpty ? '—' : appUser.favouriteVenue,
        icon: Icons.location_on,
      ),
      _StatItem(
        label: 'Fave genre',
        value: appUser.favouriteGenre.isEmpty ? '—' : appUser.favouriteGenre,
        icon: Icons.music_note,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < items.length; i++)
          Expanded(
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
                  Icon(items[i].icon, color: kAccent, size: 16),
                  const SizedBox(height: 8),
                  Text(items[i].value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(items[i].label, style: const TextStyle(color: kDim, fontSize: 10, letterSpacing: 0.2)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _clubsCard(List<String> clubs) {
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
