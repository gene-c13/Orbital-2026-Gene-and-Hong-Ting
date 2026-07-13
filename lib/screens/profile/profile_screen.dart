import 'package:after_hours/screens/profile/friends_screen.dart';
import 'package:flutter/material.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/screens/auth/login_screen.dart';
import 'package:after_hours/widgets/navigation_helper.dart';
import 'package:after_hours/services/auth_service.dart';
import 'package:after_hours/services/user_service.dart';
import 'package:after_hours/models/user.dart';
import 'package:after_hours/widgets/user_avatar.dart';
import 'package:after_hours/screens/profile/edit_profile_sheet.dart';
import 'package:after_hours/widgets/primary_button.dart';
import 'package:after_hours/widgets/user_posts_list.dart';
import 'package:after_hours/widgets/post_card.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _openEditPopup(AppUser? appUser) {
    final auth = AuthService();
    final user = auth.currentUser;
    if (user == null) return;
    final displayName = auth.currentDisplayName;
    final genre    = appUser?.favouriteGenre ?? '';
    final venue    = appUser?.favouriteVenue ?? '';
    final photoUrl = appUser?.photoUrl ?? '';


    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(
        initialName:     displayName,
        username:        appUser?.username ?? '',
        initialVenue:    venue,
        initialGenre:    genre.isEmpty    ? null : genre,
        initialPhotoUrl: photoUrl.isEmpty ? null : photoUrl,
        initialIsPublic: appUser?.isPublic ?? true,
        uid:             user.uid,
        onSaved:         () {},
        initialBio:      appUser?.bio ?? '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final user = auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    final displayName = auth.currentDisplayName;

    return StreamBuilder<AppUser?>(
      stream: UserService().userStream(user.uid),
      builder: (context, snapshot) {
        final appUser = snapshot.data;

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
                          onTap: () async {
                            await AuthService().signOut();
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
                    child: !snapshot.hasData
                        ? const Center(child: CircularProgressIndicator(color: kAccent, strokeWidth: 2))
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            
                                _bioHeader(appUser, displayName),
                                const SizedBox(height: 24),

                                const SizedBox(height: 20),

                                if (appUser != null && appUser.clubsVisited.isNotEmpty)
                                  _iconRow(Icons.location_on_outlined, 'Previously at: ${appUser.clubsVisited.join(', ')}'),

                                if (appUser != null && appUser.favouriteGenre.isNotEmpty)
                                  _iconRow(Icons.music_note_outlined, 'Obsessed with: ${appUser.favouriteGenre}'),

                                if (appUser != null && appUser.favouriteVenue.isNotEmpty)
                                  _iconRow(Icons.favorite_border, 'Home club: ${appUser.favouriteVenue}'),

                                if (appUser != null)
                                  _iconRow(Icons.local_bar_outlined,
                                      'Out ${appUser.hoursThisMonth.toStringAsFixed(1)}h across ${appUser.eventsThisMonth} nights this month'),

                                if (appUser != null)
                                  _iconRow(Icons.confirmation_number_outlined, '${appUser.totalEvents} events all-time'),

                                if (appUser != null)
                                  _iconRow(Icons.sick_outlined, '${appUser.pukeCount} 🤮 lifetime'),

                                const SizedBox(height: 24),
                                UserPostsList(
                                  uid: user.uid,
                                  viewerUid: user.uid,
                                  itemBuilder: (context, doc) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    return PostCard(postId: doc.id, data: data);
                                  },
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _bioHeader(AppUser? appUser, String displayName) {
  return Column(
    children: [
      UserAvatar(
        photoUrl: appUser?.photoUrl,
        displayName: displayName,
        radius: 120,        // big centered circle
        fontSize: 34,
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: PrimaryButton(
              label: 'Edit profile',
              height: 44,
              onPressed: () => _openEditPopup(appUser),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FriendsScreen())
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: kBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Friends',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
            ),
            if ((appUser?.bio ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                appUser!.bio,
                style: const TextStyle(color: kMuted, fontSize: 14, height: 1.4),
              ),
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


}

// ── Supporting types ──────────────────────────────────────────────────────────



