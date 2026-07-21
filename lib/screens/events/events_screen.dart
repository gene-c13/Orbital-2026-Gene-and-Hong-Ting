import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/models/event.dart';
import 'package:after_hours/models/user.dart';
import 'package:after_hours/services/event_service.dart';
import 'package:after_hours/services/attendance_service.dart';
import 'package:after_hours/services/user_service.dart';
import 'package:after_hours/screens/events/event_detail_screen.dart';
import 'package:after_hours/widgets/navigation_helper.dart';
import 'package:after_hours/widgets/user_avatar.dart';
import 'package:after_hours/utils/event_search.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  DateTime selectedDate = DateTime.now();
  final EventService _eventService = EventService();

  //the different states this screen needs to remember
  bool _searching = false;
  String _query = ''; //what has user typed so far
  final _searchController = TextEditingController();

  // stream stored as a field so it's only created when the date actually changes,
  // if its in build(), it will create new stream every rebuild (every keystroke, every setState)
  late Stream<List<Event>> _dayStream; //late cos not assigned yet, depenendent on EVentService instant initialised

  // search results stream, made once here for the same reason
  late Stream<List<Event>> _searchStream;

  @override
  void initState() { //initState is for late variables, when u need to set something up before screen shows up
    super.initState();
    _dayStream = _eventService.getEventsByDateStream(_dateKey);
    _searchStream = _eventService.getAllEventsStream();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _searching = !_searching;
      if (!_searching) {
        _searchController.clear();
        _query = '';
      }
    });
  }

  String get _dateKey => DateFormat('yyyy-MM-dd').format(selectedDate); //turns selected date into a format that fireStore date field uses
 
  Future<void> _pickDate() async { 
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: kAccent),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
      selectedDate = picked;
      _dayStream = _eventService.getEventsByDateStream(_dateKey); // recreate stream for picked date
    });
    }
  }
 
  void _changeDay(int days) { 
    setState(() {
      selectedDate = selectedDate.add(Duration(days: days));
      _dayStream = _eventService.getEventsByDateStream(_dateKey); // recreate stream for new date
    });
  }

  @override
  Widget build(BuildContext context) { //runs on every setState()
    return Scaffold(
      bottomNavigationBar: buildNavBar(0, (i) { if (i != 0) goToTab(context, i); }),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: kBgDecoration,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const Divider(height: 1, thickness: 1, color: kBorder),
              Expanded(
                child: _searching //if _searching is true, show search results, else show date stream
                    ? _buildSearchResults()
                    : StreamBuilder<List<Event>>(
                        stream: _dayStream,
                        builder: (context, snapshot) => _buildEventList(snapshot),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AFTER HOURS',
                style: kNectarine(size: 34, letterSpacing: 2),
              ),
              GestureDetector(
                onTap: _toggleSearch,
                child: Icon(
                  _searching ? Icons.close : Icons.search,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (_searching)
            _buildSearchField()
          else ...[
            Row(
              children: [
                GestureDetector(
                  onTap: () => _changeDay(-1),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 14),
                    child: Icon(Icons.chevron_left, color: Colors.white, size: 30),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Column(
                      children: [
                        Text(
                          DateFormat('EEEE').format(selectedDate).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          DateFormat('d MMMM y').format(selectedDate),
                          style: const TextStyle(color: kMuted, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _changeDay(1),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 14),
                    child: Icon(Icons.chevron_right, color: Colors.white, size: 30),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Event>>(
              stream: _dayStream,
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                if (count == 0) return const SizedBox.shrink();
                return Text(
                  '$count ${count == 1 ? "event" : "events"} tonight',
                  style: const TextStyle(color: kDim, fontSize: 12, letterSpacing: 0.3),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: kAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              cursorColor: kAccent,
              decoration: const InputDecoration(
                hintText: 'Search venue, DJ, or genre',
                hintStyle: TextStyle(color: kDim, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(AsyncSnapshot<List<Event>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator(color: kAccent, strokeWidth: 2));
    }
    if (snapshot.hasError) {
      return const Center(
        child: Text('Something went wrong.', style: TextStyle(color: kMuted)),
      );
    }
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.nightlife, color: kDim, size: 56),
            const SizedBox(height: 18),
            const Text(
              'Nothing on tonight.',
              style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text('Try a different date.', style: TextStyle(color: kDim, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder( //ListView displays its children one after another in scrollable list
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      itemCount: snapshot.data!.length,
      itemBuilder: (context, index) => _eventCard(snapshot.data![index]),
    );
  }

  Widget _eventCard(Event event) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: kAccent, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.venue,
                              style: const TextStyle(color: kMuted, fontSize: 13, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (event.hasGuestlist) ...[
                      _guestlistBadge(),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      event.price,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, color: kAccent, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          event.time,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.music_note, color: kAccent, size: 14),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    event.dj,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: event.genres.map(_genreTag).toList(),
                  ),
                ),
                const SizedBox(width: 8),
                _crowdLevel(event.crowdLevel),
              ],
            ),
            _AttendanceSnippet(eventId: event.id),
          ],
        ),
      ),
    );
  }

  Widget _guestlistBadge() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bolt, color: kAccent, size: 13),
        SizedBox(width: 3),
        Text('Guestlist', style: TextStyle(color: kAccent, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _crowdLevel(String level) {
    final Color color = crowdColor(level);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Crowd Level: ', style: TextStyle(color: kDim, fontSize: 13, fontWeight: FontWeight.w500)),
        Text(level, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _genreTag(String genre) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: kAccent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(genre, style: const TextStyle(color: kMuted, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSearchResults() {
    if (_query.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, color: kDim, size: 56),
            const SizedBox(height: 18),
            const Text(
              'Search every night.',
              style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text('By venue, DJ, or genre.', style: TextStyle(color: kDim, fontSize: 13)),
          ],
        ),
      );
    }

    return StreamBuilder<List<Event>>( 
      stream: _searchStream, //when re-built, stream stays the same so theres no extra firestore read (costly)
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kAccent, strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong.', style: TextStyle(color: kMuted)));
        }

        final all = snapshot.data ?? [];
        final results = all.where((e) => matches(e, _query)).toList(); //filter locally

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off, color: kDim, size: 56),
                const SizedBox(height: 18),
                Text(
                  'No matches for "$_query".',
                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text('Try a venue, DJ, or genre.', style: TextStyle(color: kDim, fontSize: 13)),
              ],
            ),
          );
        }

        final groups = <String, List<Event>>{}; //groups is a Map, group same date events together
        for (final e in results) {
          groups.putIfAbsent(e.date, () => []).add(e); //if e.date absent, create empty list. both scenarios, add the event into the list in the dict
        }

        final children = <Widget>[];
        groups.forEach((date, events) {
          children.add(_dateHeader(date));
          children.addAll(events.map(_eventCard));
        });

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: children,
        );
      },
    );
  }

  Widget _dateHeader(String date) {
    final parsed = DateTime.tryParse(date);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isToday = date == today;
    String label = date;
    if (parsed != null) {
      final formatted = DateFormat('EEE d MMM').format(parsed).toUpperCase();
      label = isToday ? 'TONIGHT · $formatted' : formatted;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Text(
        label,
        style: TextStyle(
          color: isToday ? kAccent : kMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

/// "John, Emma, and 3 others are going!" with up to 3 overlapping profile
/// pictures — hidden entirely if no one's marked themselves attending yet.
class _AttendanceSnippet extends StatefulWidget {
  final String eventId;
  const _AttendanceSnippet({required this.eventId});

  @override
  State<_AttendanceSnippet> createState() => _AttendanceSnippetState();
}

class _AttendanceSnippetState extends State<_AttendanceSnippet> {
  // stream and future kept in state so scrolling the list doesn't keep
  // re-subscribing and re-fetching the same profiles (same trick as
  // _AttendeePreview in event_detail_screen.dart)
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

        // only fetch profiles again when the attendee count changes,
        // not every rebuild (same trick as _lastMessageCount in chat_screen)
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

  /// Small overlapping circle-avatar cluster, up to 3 people, rightmost on
  /// top, with a thin "cutout" ring matching the card background so the
  /// overlap reads cleanly instead of avatars just butting up against
  /// each other.
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
