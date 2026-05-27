import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'event.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  DateTime selectedDate = DateTime.now();

  // Dummy events for now — Hong Ting will replace this with real data from Firestore.
  final List<Event> events = const [
    Event(
      name: 'Capital',
      venue: 'Zouk Singapore',
      dj: 'DJ Koflow',
      time: '10:00 PM',
      price: '\$25 - \$35',
      crowdLevel: 'High',
      genres: ['House', 'Techno'],
      hasGuestlist: true,
    ),
    Event(
      name: 'Skyline Sessions',
      venue: 'CÉ LA VI',
      dj: 'DJ Rattle',
      time: '9:00 PM',
      price: '\$30 - \$40',
      crowdLevel: 'Medium',
      genres: ['Deep House', 'Nu-Disco'],
      hasGuestlist: true,
    ),
    Event(
      name: 'Cloud Nine Fridays',
      venue: '1-Altitude',
      dj: 'DJ Ramsey & Fen',
      time: '8:00 PM',
      price: '\$20 - \$30',
      crowdLevel: 'High',
      genres: ['EDM', 'Progressive House'],
    ),
  ];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _changeDay(int days) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: days));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      onPressed: () {},
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text('Logout', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _tabButton(context, Icons.calendar_today, 'Events', true),
                    const SizedBox(width: 8),
                    _tabButton(context, Icons.people, 'Social', false),
                    const SizedBox(width: 8),
                    _tabButton(context, Icons.shopping_bag, 'Marketplace', false),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                              Text('${events.length} events tonight',
                                  style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 14)),
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
                        child: ListView.builder(
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            return _eventCard(events[index]);
                          },
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

  Widget _eventCard(Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x22FFFFFF)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x339D4EDD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 14),
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
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.attach_money, color: Color(0xFFB14EFF), size: 16),
              Text(event.price, style: const TextStyle(color: Colors.white)),
              const Spacer(),
              _crowdBadge(event.crowdLevel),
            ],
          ),
          const SizedBox(height: 12),
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
        ? const Color(0xFFE8833A)
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Text(genre, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  Widget _tabButton(BuildContext context, IconData icon, String label, bool active) {
    return GestureDetector(
      onTap: () {
        if (!active) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label — coming soon!')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0x33FFFFFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}