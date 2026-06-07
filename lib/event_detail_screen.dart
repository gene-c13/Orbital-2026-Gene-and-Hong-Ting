import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'event.dart';

const Color kSurface = Color(0x14FFFFFF);
const Color kBorder = Color(0x22FFFFFF);
const Color kAccent = Color(0xFFB14EFF);
const Color kMuted = Color(0xCCFFFFFF);

class EventDetailScreen extends StatelessWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  Future<void> _launchTicketUrl(BuildContext context) async {
    if (event.ticketUrl.isEmpty) return;
    final uri = Uri.parse(event.ticketUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open ticket link.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pop();
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${['Events', 'Social', 'Marketplace', 'Profile'][index]} — coming soon!',
              ),
            ),
          );
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
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Event Details',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero card — name, venue, guestlist badge
                      _heroCard(),
                      const SizedBox(height: 16),

                      // Info grid
                      _infoGrid(),
                      const SizedBox(height: 16),

                      // Genres
                      _section(
                        label: 'Genres',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: event.genres.map(_genreTag).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (event.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _section(
                            label: 'About this event',
                            child: Text(
                              event.description,
                              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
                            ),
                          ),
                        ),

                      if (event.artistBio.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _section(
                            label: 'About the artist',
                            child: Text(
                              event.artistBio,
                              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
                            ),
                          ),
                        ),

                      // Crowd level
                      _section(
                        label: 'Expected crowd',
                        child: _crowdBar(event.crowdLevel),
                      ),
                      const SizedBox(height: 28),

                      // Buy tickets button
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

  // ── Widgets ──────────────────────────────────────────────────────────

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.hasGuestlist)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: kAccent),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, color: kAccent, size: 14),
                    SizedBox(width: 4),
                    Text('Guestlist available', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
          Text(
            event.name,
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, height: 1.2),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, color: kAccent, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(event.venue, style: const TextStyle(color: kMuted, fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoGrid() {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: kAccent, size: 20),
              const SizedBox(width: 12),
              Text(label, style: const TextStyle(color: kMuted, fontSize: 14)),
              const Spacer(),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        if (divider) Divider(height: 1, color: kBorder),
      ],
    );
  }

  Widget _section({required String label, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: kMuted, fontSize: 13, fontWeight: FontWeight.w600)),
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

    final int filledSegments = level == 'High' ? 3 : level == 'Medium' ? 2 : 1;
    final String description = level == 'High'
        ? 'Expect it to be packed — arrive early.'
        : level == 'Medium'
            ? 'Moderate crowd — comfortable evening out.'
            : 'Quiet night — plenty of space.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (i) {
            final filled = i < filledSegments;
            return Expanded(
              child: Container(
                height: 8,
                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                decoration: BoxDecoration(
                  color: filled ? color : const Color(0x33FFFFFF),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color),
              ),
              child: Text(level, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF241B30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(genre, style: const TextStyle(color: Colors.white, fontSize: 13)),
    );
  }

  Widget _buyButton(BuildContext context) {
    final bool hasLink = event.ticketUrl.isNotEmpty;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: hasLink ? () => _launchTicketUrl(context) : null,
        icon: const Icon(Icons.confirmation_number_outlined),
        label: Text(hasLink ? 'Buy Tickets' : 'Tickets — check at door'),
        style: ElevatedButton.styleFrom(
          backgroundColor: kAccent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0x44FFFFFF),
          disabledForegroundColor: kMuted,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
