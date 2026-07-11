import 'package:flutter/material.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/services/auth_service.dart';
import 'package:after_hours/models/user.dart';
import 'package:after_hours/services/attendance_service.dart';
import 'package:after_hours/services/user_service.dart';
import 'package:after_hours/services/friend_service.dart';
import 'package:after_hours/widgets/user_avatar.dart';
import 'package:after_hours/widgets/tap_to_profile.dart';
import 'package:after_hours/widgets/navigation_helper.dart';

class AttendeeListScreen extends StatelessWidget {
  final String eventId;
  final String eventName;

  const AttendeeListScreen({
    super.key,
    required this.eventId,
    required this.eventName,
  });

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
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Who's going",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            eventName,
                            style: const TextStyle(color: kMuted, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: kBorder),
              Expanded(
                child: StreamBuilder<List<String>>(
                  stream: AttendanceService().attendeeUidsStream(eventId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: kAccent, strokeWidth: 2));
                    }

                    final uids = snapshot.data ?? [];
                    if (uids.isEmpty) {
                      return const Center(
                        child: Text(
                          'No one has marked themselves going yet.',
                          style: TextStyle(color: kDim),
                        ),
                      );
                    }

                    return FutureBuilder<List<AppUser>>(
                      future: UserService().getUsers(uids),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData) {
                          return const Center(child: CircularProgressIndicator(color: kAccent, strokeWidth: 2));
                        }

                        final users = userSnap.data!
                            .where((u) => u.uid != currentUid)
                            .toList();

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return _AttendeeTile(
                              user: user,
                              currentUid: currentUid,
                            );
                          },
                        );
                      },
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
}

class _AttendeeTile extends StatefulWidget {
  final AppUser user;
  final String currentUid;
  
  

  const _AttendeeTile({required this.user, required this.currentUid});

  @override
  State<_AttendeeTile> createState() => _AttendeeTileState();
}

class _AttendeeTileState extends State<_AttendeeTile> {

  bool _hovering = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hovering = true),
              onExit: (_) => setState(() => _hovering = false),
              child: TapToProfile(
                uid: widget.user.uid,
                child: Row(
                  children: [
                    UserAvatar(
                      photoUrl: widget.user.photoUrl,
                      displayName: widget.user.name,
                      radius: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.user.name,
                        style: TextStyle(
                          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700,
                            decoration: _hovering ? TextDecoration.underline : TextDecoration.none,
                            decorationColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
            )
            
          ),
          FutureBuilder<bool>(
            future: FriendService().isFriend(widget.currentUid, widget.user.uid),
            builder: (context, snap) {
              if (!snap.hasData || !snap.data!) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => openChat(context, widget.user.uid, widget.user.name),
                child: const Text('Message', style: TextStyle(color: kAccent, fontWeight: FontWeight.w700)),
              );
            },
          ),
        ],
      ),
    );
  }
}
