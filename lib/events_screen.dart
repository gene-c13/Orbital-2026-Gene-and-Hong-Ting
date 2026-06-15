import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'app_theme.dart';
import 'event.dart';
import 'event_service.dart';
import 'event_detail_screen.dart';
import 'navigation_helper.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  DateTime selectedDate = DateTime.now();
  final EventService _eventService = EventService();

  String get _dateKey => DateFormat('yyyy-MM-dd').format(selectedDate);

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
    if (picked != null) setState(() => selectedDate = picked);
  }

  void _changeDay(int days) {
    setState(() => selectedDate = selectedDate.add(Duration(days: days)));
  }

  @override
  Widget build(BuildContext context) {
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
                child: StreamBuilder<List<Event>>(
                  stream: _eventService.getEventsByDateStream(_dateKey),
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
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AFTER HOURS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              GestureDetector(
                onTap: () => _changeDay(-1),
                child: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.chevron_left, color: Colors.white, size: 28),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('d MMMM y').format(selectedDate),
                        style: const TextStyle(color: kMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _changeDay(1),
                child: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(Icons.chevron_right, color: Colors.white, size: 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<Event>>(
            stream: _eventService.getEventsByDateStream(_dateKey),
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
            Icon(Icons.nightlife, color: kDim, size: 52),
            const SizedBox(height: 16),
            const Text(
              'Nothing on tonight.',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text('Try a different date.', style: TextStyle(color: kDim, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
        margin: const EdgeInsets.only(bottom: 12),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorder),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 3,
              child: Container(color: kAccent),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (event.hasGuestlist) ...[
                        const SizedBox(width: 8),
                        _guestlistBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(event.venue, style: const TextStyle(color: kMuted, fontSize: 12)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.music_note, color: kAccent, size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.dj,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _dot(),
                      const Icon(Icons.access_time, color: kAccent, size: 13),
                      const SizedBox(width: 3),
                      Text(event.time, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      _dot(),
                      Text(event.price, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 10),
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
                      _crowdBadge(event.crowdLevel),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 5),
    child: Text('·', style: TextStyle(color: kDim, fontSize: 14)),
  );

  Widget _guestlistBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kAccent),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, color: kAccent, size: 12),
          SizedBox(width: 2),
          Text('GL', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _crowdBadge(String level) {
    final Color color = level == 'High'
        ? const Color(0xFFFF6B3D)
        : level == 'Medium'
            ? const Color(0xFFE0C040)
            : const Color(0xFF4CAF50);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Text(
        level.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _genreTag(String genre) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x22B14EFF),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(genre, style: const TextStyle(color: kMuted, fontSize: 11)),
    );
  }
}
