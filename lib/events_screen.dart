import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'event.dart';
import 'event_service.dart';
import 'event_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';


const Color kSurface = Color(0x14FFFFFF);  // translucent white card
const Color kBorder = Color(0x22FFFFFF);   // subtle border
const Color kAccent = Color(0xFFB14EFF);   // purple accent
const Color kMuted = Color(0xCCFFFFFF);    // faded white

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  DateTime selectedDate = DateTime.now();
  int _selectedTab = 0;

  // Dummy events for now — Hong Ting will replace this with real data from Firestore.
  final EventService _eventService = EventService();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  void _changeDay(int days) {
    setState(() => selectedDate = selectedDate.add(Duration(days: days)));
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _selectedTab,
      onTap: (index) {
        if (index != 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${['Events','Social','Marketplace','Profile'][index]} — coming soon!')),
          );
          return;
        }
        setState(() => _selectedTab = index);
      },
      backgroundColor: const Color(0xFF1A0A3B),
      selectedItemColor: kAccent,
      unselectedItemColor: kMuted,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Events'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Social'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Marketplace'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    ),
    body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E1065), Color(0xFF5B21B6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('After Hours',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (!context.mounted) return;
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text('Logout', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0x33FFFFFF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(DateFormat('EEEE').format(selectedDate),
                                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(DateFormat('d MMMM y').format(selectedDate),
                                  style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 16)),
                              const SizedBox(height: 8),
                              StreamBuilder<List<Event>>(
                                stream: _eventService.getEventsByDateStream(
                                  DateFormat('yyyy-MM-dd').format(selectedDate),
                                ),
                                builder: (context, snapshot) {
                                  final count = snapshot.data?.length ?? 0;
                                  return Text('$count events tonight',
                                      style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 14));
                                },
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => _changeDay(-1),
                                icon: const Icon(Icons.chevron_left, color: Colors.white),
                              ),
                              OutlinedButton.icon(
                                onPressed: _pickDate,
                                icon: const Icon(Icons.calendar_today, color: Colors.white, size: 16),
                                label: const Text('Select Date', style: TextStyle(color: Colors.white)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0x33FFFFFF)),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _changeDay(1),
                                icon: const Icon(Icons.chevron_right, color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: StreamBuilder<List<Event>>(
                          stream: _eventService.getEventsByDateStream(
                            DateFormat('yyyy-MM-dd').format(selectedDate),
                          ),
                          builder: (context, snapshot) => _buildEventList(snapshot),
                        ),
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
  }

  Widget _buildEventList(AsyncSnapshot<List<Event>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (snapshot.hasError) {
      return const Center(
        child: Text(
          'Something went wrong. Please try again.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return const Center(
        child: Text(
          'No events tonight.\nCheck back later or pick another date.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    final events = snapshot.data!;
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => EventDetailScreen(event: event)),
          ),
          child: _eventCard(event),
        );
      },
    );
  }

  Widget _eventCard(Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(event.name,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              if (event.hasGuestlist)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: kAccent),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt, color: kAccent, size: 14),
                      SizedBox(width: 4),
                      Text('Guestlist', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(event.venue, style: const TextStyle(color: Color(0xCCFFFFFF))),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.music_note, color: Color(0xFFB14EFF), size: 16),
              const SizedBox(width: 4),
              Text(event.dj, style: const TextStyle(color: Colors.white)),
              const Spacer(),
              const Icon(Icons.access_time, color: Color(0xFFB14EFF), size: 16),
              const SizedBox(width: 4),
              Text(event.time, style: const TextStyle(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.attach_money, color: Color(0xFFB14EFF), size: 16),
              Text(event.price, style: const TextStyle(color: Colors.white)),
              const Spacer(),
              _crowdBadge(event.crowdLevel),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: event.genres.map((g) => _genreTag(g)).toList(),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(level, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _genreTag(String genre) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF241B30),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(genre, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}