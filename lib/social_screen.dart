import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_post_screen.dart';
import 'navigation_helper.dart';

const Color kSurface = Color(0x14FFFFFF);
const Color kBorder  = Color(0x22FFFFFF);
const Color kAccent  = Color(0xFFB14EFF);
const Color kMuted   = Color(0xCCFFFFFF);

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 1) return; // already here
          goToTab(context, index);
        },
        backgroundColor: const Color(0xFF1A0A3B),
        selectedItemColor: kAccent,
        unselectedItemColor: kMuted,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.people),         label: 'Social'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag),   label: 'Marketplace'),
          BottomNavigationBarItem(icon: Icon(Icons.person),         label: 'Profile'),
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
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
                child: Row(
                  children: [
                    const Text(
                      'Social',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: kAccent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 18),
                            SizedBox(width: 4),
                            Text('Log night', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Feed from Firestore
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .orderBy('created_at', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Something went wrong.', style: TextStyle(color: Colors.white70)),
                      );
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No posts yet.\nBe the first to log a night!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final postId = docs[index].id;
                        return _PostCard(postId: postId, data: data);
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

// ── Post card ─────────────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> data;

  const _PostCard({required this.postId, required this.data});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool get _liked {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final likes = List<String>.from(widget.data['likes'] ?? []);
    return likes.contains(uid);
  }

  int get _likeCount => (widget.data['likes'] as List?)?.length ?? 0;

  Future<void> _toggleLike() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ref = FirebaseFirestore.instance.collection('posts').doc(widget.postId);
    if (_liked) {
      await ref.update({'likes': FieldValue.arrayRemove([uid])});
    } else {
      await ref.update({'likes': FieldValue.arrayUnion([uid])});
    }
  }

  String _timeAgo(Timestamp? ts) {
    if (ts == null) return '';
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final data         = widget.data;
    final username     = data['username'] as String? ?? 'Raver';
    final caption      = data['caption']  as String? ?? '';
    final venueTag     = (data['venue_tag'] as String?)?.trim() ?? '';
    final eventTag     = (data['event_tag'] as String?)?.trim() ?? '';
    final rating       = (data['rating'] as num?)?.toDouble();
    final commentCount = (data['comment_count'] as int?) ?? 0;
    final ts           = data['created_at'] as Timestamp?;
    final puked        = data['puked'] as bool? ?? false;
    final startTime    = data['start_time'] as String?;
    final endTime      = data['end_time'] as String?;
    final hoursOut     = (data['hours_out'] as num?)?.toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: kAccent.withValues(alpha: 0.35),
                  child: Text(
                    username[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(_timeAgo(ts), style: const TextStyle(color: kMuted, fontSize: 11)),
                    ],
                  ),
                ),
                if (puked) _pukeBadge(),
                if (rating != null) _ratingBadge(rating),
              ],
            ),
          ),

          // Tags
          if (venueTag.isNotEmpty || eventTag.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Wrap(
                spacing: 8,
                children: [
                  if (venueTag.isNotEmpty) _tag(Icons.location_on, venueTag),
                  if (eventTag.isNotEmpty) _tag(Icons.confirmation_number, eventTag),
                ],
              ),
            ),

          // Time + hours
          if (startTime != null || hoursOut != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: kMuted, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    [
                      if (startTime != null && endTime != null) '$startTime – $endTime',
                      if (hoursOut != null) '${hoursOut!.toStringAsFixed(1)}h out',
                    ].join('  ·  '),
                    style: const TextStyle(color: kMuted, fontSize: 12),
                  ),
                ],
              ),
            ),

          // Caption
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Text(caption, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
          ),

          Divider(height: 1, color: kBorder),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _toggleLike,
                  icon: Icon(
                    _liked ? Icons.favorite : Icons.favorite_border,
                    color: _liked ? const Color(0xFFFF6B8A) : kMuted,
                    size: 18,
                  ),
                  label: Text(
                    '$_likeCount',
                    style: TextStyle(color: _liked ? const Color(0xFFFF6B8A) : kMuted, fontSize: 13),
                  ),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10)),
                ),
                TextButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Comments — coming soon!')),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, color: kMuted, size: 18),
                  label: Text('$commentCount', style: const TextStyle(color: kMuted, fontSize: 13)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pukeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x55FFFFFF)),
      ),
      child: const Text('🤮', style: TextStyle(fontSize: 13)),
    );
  }

  Widget _ratingBadge(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kAccent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: kAccent, size: 13),
          const SizedBox(width: 3),
          Text(
            rating % 1 == 0 ? '${rating.toInt()}' : '$rating',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _tag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF241B30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kAccent, size: 12),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: kMuted, fontSize: 12)),
        ],
      ),
    );
  }
}