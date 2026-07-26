import 'package:flutter/material.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/models/user.dart';
import 'package:after_hours/services/attendance_service.dart';
import 'package:after_hours/services/user_service.dart';
import 'package:after_hours/widgets/user_avatar.dart';

//shows "John, Emma, and 3 others are going!" with up to 3 overlapping
//profile pictures. hidden completely if nobody is going yet
class AttendanceSnippet extends StatefulWidget {
  final String eventId;
  const AttendanceSnippet({super.key, required this.eventId});

  @override
  State<AttendanceSnippet> createState() => _AttendanceSnippetState();
}

class _AttendanceSnippetState extends State<AttendanceSnippet> {
  //stream and future kept in state so scrolling the list doesn't keep
  //re-subscribing and re-fetching the same profiles (same trick as
  //_AttendeePreview in event_detail_screen.dart)
  Stream<List<String>>? _uidsStream;
  Future<List<AppUser>>? _usersFuture;
  int _lastCount = -1; // how many attendees we last fetched profiles for

  @override
  void initState() {
    super.initState();
    if (widget.eventId.isNotEmpty) {
      _uidsStream = AttendanceService().attendeeUidsStream(widget.eventId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_uidsStream == null) return const SizedBox.shrink();

    return StreamBuilder<List<String>>(
      stream: _uidsStream,
      builder: (context, snapshot) {
        final uids = snapshot.data ?? [];
        if (uids.isEmpty) return const SizedBox.shrink();

        //only fetch profiles again when the attendee count changes,
        //not every rebuild (same trick as _lastMessageCount in chat_screen)
        if (uids.length != _lastCount) {
          _lastCount = uids.length;
          _usersFuture = UserService().getUsers(uids.take(3).toList());
        }

        return FutureBuilder<List<AppUser>>(
          future: _usersFuture,
          builder: (context, userSnap) {
            final users = userSnap.data ?? [];
            if (users.isEmpty) return const SizedBox.shrink();

            final names = users.take(2).map((u) => u.name).toList();

            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  _avatarStack(users),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _attendanceText(names, uids.length),
                      style: const TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  //small cluster of up to 3 overlapping avatars, rightmost on top. the thin
  //ring around each one matches the card background so the overlap reads clean
  Widget _avatarStack(List<AppUser> users) {
    const double size = 22;
    const double overlap = 14;
    final shown = users.take(3).toList();

    return SizedBox(
      width: overlap * (shown.length - 1) + size,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * overlap,
              child: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: const BoxDecoration(
                  color: kSurface,
                  shape: BoxShape.circle,
                ),
                child: UserAvatar(
                  photoUrl: shown[i].photoUrl,
                  displayName: shown[i].name,
                  radius: size / 2 - 1.5,
                  fontSize: 9,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _attendanceText(List<String> names, int total) {
    final others = total - names.length;
    final othersLabel = others == 1 ? 'other' : 'others';

    if (names.length == 1) {
      return others > 0
          ? '${names[0]} and $others $othersLabel are going!'
          : '${names[0]} is going!';
    }

    return others > 0
        ? '${names[0]}, ${names[1]}, and $others $othersLabel are going!'
        : '${names[0]} and ${names[1]} are going!';
  }
}
