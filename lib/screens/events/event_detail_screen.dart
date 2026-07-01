import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/models/event.dart';
import 'package:after_hours/models/user.dart';
import 'package:after_hours/services/attendance_service.dart';
import 'package:after_hours/services/user_service.dart';
import 'package:after_hours/services/friend_service.dart';
import 'package:after_hours/services/chat_service.dart';
import 'package:after_hours/screens/events/attendee_list_screen.dart';
import 'package:after_hours/screens/chat/chat_screen.dart';
import 'package:after_hours/widgets/navigation_helper.dart';
import 'package:after_hours/widgets/user_avatar.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

Future<void> _launchBookingUrl(BuildContext context) async {
  if (event.bookingUrl.isEmpty) return;
  final uri = Uri.parse(event.bookingUrl);

  final bool launched = await launchUrl(
    uri,
    mode: LaunchMode.platformDefault,
    webOnlyWindowName: '_blank',
  );

  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open ticket link.')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: buildNavBar(0, (i) {
        if (i == 0) {
          Navigator.of(context).pop();
          return;
        }
        goToTab(context, i);
      }),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: kBgDecoration,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Event Details',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: kBorder),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _heroCard(),
                      const SizedBox(height: 12),
                      _infoGrid(),
                      const SizedBox(height: 12),
                      _attendanceSection(context),
                      const SizedBox(height: 12),
                      _section(
                        label: 'Genres',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: event.genres.map(_genreTag).toList(),
                        ),
                      ),

                      if (event.description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _section(
                          label: 'About this event',
                          child: Text(
                            event.description,
                            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
                          ),
                        ),
                      ],

                      if (event.artistBio.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _section(
                          label: 'About the artist',
                          child: Text(
                            event.artistBio,
                            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      _section(
                        label: 'Expected crowd',
                        child: _crowdBar(event.crowdLevel),
                      ),
                      const SizedBox(height: 24),
                      _buyButton(context),
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

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // show event image at the top if imageUrl is not empty
          if (event.imageUrl.isNotEmpty)
            Image.network(
              'https://images.weserv.nl/?url=${Uri.encodeComponent(event.imageUrl)}',
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Stack(
              children: [
                Positioned(left: 0, top: 0, bottom: 0, width: 3, child: Container(color: kAccent)),
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (event.hasGuestlist)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: kAccent),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt, color: kAccent, size: 13),
                                SizedBox(width: 3),
                                Text('Guestlist available', style: TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      Text(
                        event.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: kAccent, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(event.venue, style: const TextStyle(color: kMuted, fontSize: 14)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoGrid() {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          _infoRow(Icons.music_note, 'DJ / Artist', event.dj, divider: true),
          _infoRow(Icons.access_time, 'Doors open', event.time, divider: true),
          _infoRow(Icons.confirmation_number, 'Ticket price', event.price, divider: false),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {required bool divider}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: kAccent, size: 18),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(color: kMuted, fontSize: 13)),
              const Spacer(),
              Text(value,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (divider) const Divider(height: 1, color: kBorder),
      ],
    );
  }

  Widget _attendanceSection(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<List<String>>(
      stream: AttendanceService().attendeeUidsStream(event.id),
      builder: (context, snapshot) {
        final uids = snapshot.data ?? [];
        final isAttending = currentUid != null && uids.contains(currentUid);

        return _section(
          label: "Who's going",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      uids.isEmpty ? 'No one yet — be the first!' : '${uids.length} going',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                  _goingButton(currentUid, isAttending),
                ],
              ),
              if (uids.isNotEmpty) ...[
                const SizedBox(height: 14),
                FutureBuilder<List<AppUser>>(
                  future: UserService().getUsers(uids.take(5).toList()),
                  builder: (context, userSnap) {
                    if (!userSnap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(child: CircularProgressIndicator(color: kAccent, strokeWidth: 2)),
                      );
                    }

                    final users = userSnap.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...users.map((user) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  UserAvatar(photoUrl: user.photoUrl, displayName: user.name, radius: 16),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      user.name,
                                      style: const TextStyle(color: Colors.white, fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (user.uid != currentUid)
                                    FutureBuilder<bool>(
                                      future: FriendService().isFriend(currentUid ?? '', user.uid),
                                      builder: (context, friendSnap) {
                                        if (!friendSnap.hasData || !friendSnap.data!) return const SizedBox.shrink();
                                        return TextButton(
                                          onPressed: () async {
                                            final navigator = Navigator.of(context);
                                            await ChatService().getOrCreateChat(currentUid!, user.uid);
                                            navigator.push(
                                              MaterialPageRoute(
                                                builder: (_) => ChatScreen(
                                                  otherUid: user.uid,
                                                  otherDisplayName: user.name,
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Text('Message', style: TextStyle(color: kAccent, fontSize: 13, fontWeight: FontWeight.w700)),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            )),
                        if (uids.length > 5)
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AttendeeListScreen(eventId: event.id, eventName: event.name),
                              ),
                            ),
                            child: Text(
                              'See all ${uids.length}',
                              style: const TextStyle(color: kAccent, fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _goingButton(String? uid, bool isAttending) {
    if (uid == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        if (isAttending) {
          AttendanceService().unmarkAttending(event.id, uid);
        } else {
          AttendanceService().markAttending(event.id, uid);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isAttending ? Colors.transparent : kAccent,
          borderRadius: BorderRadius.circular(20),
          border: isAttending ? Border.all(color: kAccent) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAttending ? Icons.check : Icons.add,
              color: isAttending ? kAccent : Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              isAttending ? 'Going' : "I'm going",
              style: TextStyle(
                color: isAttending ? kAccent : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({required String label, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(color: kDim, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _crowdBar(String level) {
    final Color color = level == 'High'
        ? const Color(0xFFFF6B3D)
        : level == 'Medium'
            ? const Color(0xFFE0C040)
            : const Color(0xFF4CAF50);

    final int filled = level == 'High' ? 3 : level == 'Medium' ? 2 : 1;
    final String description = level == 'High'
        ? 'Packed — arrive early.'
        : level == 'Medium'
            ? 'Moderate crowd — comfortable night out.'
            : 'Quiet — plenty of room.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (i) {
            return Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                decoration: BoxDecoration(
                  color: i < filled ? color : const Color(0x22FFFFFF),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color),
              ),
              child: Text(
                level.toUpperCase(),
                style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(description, style: const TextStyle(color: kMuted, fontSize: 13)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _genreTag(String genre) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x22B14EFF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(genre, style: const TextStyle(color: kMuted, fontSize: 12)),
    );
  }

  Widget _buyButton(BuildContext context) {
    final bool hasLink = event.bookingUrl.isNotEmpty;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Container(
        decoration: hasLink ? kPrimaryButtonDecoration : null,
        child: ElevatedButton.icon(
          onPressed: hasLink ? () => _launchBookingUrl(context) : null,
          icon: const Icon(Icons.confirmation_number_outlined, size: 18),
          label: Text(hasLink ? 'Buy Tickets' : 'Tickets — check at door'),
          style: ElevatedButton.styleFrom(
            backgroundColor: hasLink ? Colors.transparent : const Color(0x33FFFFFF),
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: kMuted,
            disabledBackgroundColor: const Color(0x22FFFFFF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
