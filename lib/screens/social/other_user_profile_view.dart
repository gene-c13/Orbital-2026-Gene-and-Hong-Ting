import 'package:flutter/material.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/services/auth_service.dart';
import 'package:after_hours/services/user_service.dart';
import 'package:after_hours/services/friend_service.dart';
import 'package:after_hours/models/user.dart';
import 'package:after_hours/widgets/user_avatar.dart';
import 'package:after_hours/widgets/navigation_helper.dart';
import 'package:after_hours/widgets/primary_button.dart';

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
                          _bioHeader(context, currentUid, appUser, appUser.displayName),
                          const SizedBox(height: 16),
                          if (appUser.clubsVisited.isNotEmpty)
                            _iconRow(Icons.location_on_outlined, 'Previously at: ${appUser.clubsVisited.join(', ')}'),

                          if (appUser.favouriteGenre.isNotEmpty)
                            _iconRow(Icons.music_note_outlined, 'Obsessed with: ${appUser.favouriteGenre}'),

                          if (appUser.favouriteVenue.isNotEmpty)
                            _iconRow(Icons.favorite_border, 'Home club: ${appUser.favouriteVenue}'),

                          
                          _iconRow(Icons.local_bar_outlined,
                                'Out ${appUser.hoursThisMonth.toStringAsFixed(1)}h across ${appUser.eventsThisMonth} nights this month'),

                        
                          _iconRow(Icons.confirmation_number_outlined, '${appUser.totalEvents} events all-time'),

                        
                          _iconRow(Icons.sick_outlined, '${appUser.pukeCount} 🤮 lifetime'),

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



  Widget _bioHeader(BuildContext context, String currentUid, AppUser? appUser, String displayName) {
  return Column(
    children: [
      UserAvatar(
        photoUrl: appUser?.photoUrl,
        displayName: displayName,
        radius: 120,        // big centered circle
        fontSize: 34,
      ),
      const SizedBox(height: 16),
      
      FutureBuilder<List<bool>>(
        future: Future.wait([
          _friendService.isFriend(currentUid, appUser!.uid),
          _friendService.hasPendingRequest(currentUid, appUser.uid),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox(height: 44);   // hold the space while loading

          final alreadyFriend = snapshot.data![0];
          final pending       = snapshot.data![1] || _requestSent;
          final canMessage    = alreadyFriend || appUser.isPublic;

          final followLabel = alreadyFriend ? 'Following'
                            : pending       ? 'Requested'
                            : '+ Add Friend';

          VoidCallback? followAction;
                if (alreadyFriend) {
                  followAction = () => _confirmUnfriend(appUser!);   // the dialog, extracted
                } else if (pending) {
                  followAction = null;                                // Requested → disabled
                } else {
                  followAction = () async {
                    await _friendService.sendFriendRequest(currentUid, appUser!.uid);
                    if (mounted) setState(() => _requestSent = true);
                  };
                }
      
      return Row(
        children: [
          Expanded(
            child: PrimaryButton(
              label: followLabel,
              height: 44,
              onPressed: followAction
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: PrimaryButton(
              label: 'Message',
              height: 44,
              onPressed: canMessage ? () => openChat(context, appUser.uid, appUser.name) : null,
            ),
          ),
        ],
      );
        },
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(displayName,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
            if ((appUser?.bio ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(appUser!.bio, style: const TextStyle(color: kMuted, fontSize: 14, height: 1.4)),
            ],
          ],
        ),
      ),
    ],
  );
}

    Widget _iconRow(IconData icon, String text) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: kDim, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

    Future<void> _confirmUnfriend(AppUser appUser) async {
      final currentUid = AuthService().currentUid ?? '';

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
    }
}
