import 'package:flutter/material.dart';

const Color kSurface = Color(0x14FFFFFF);
const Color kBorder  = Color(0x22FFFFFF);
const Color kAccent  = Color(0xFFB14EFF);
const Color kMuted   = Color(0xCCFFFFFF);

// ── Placeholder data model ─────────────────────────────────────────────
// TODO: replace with Firestore stream from 'posts' collection,
// ordered by created_at descending
class _Post {
  final String id;
  final String username;
  final String initials;
  final String caption;
  final String? venueTag;
  final String? eventTag;
  final double? rating;
  int likeCount;
  final int commentCount;
  final String timeAgo;
  bool liked;

  _Post({
    required this.id,
    required this.username,
    required this.initials,
    required this.caption,
    this.venueTag,
    this.eventTag,
    this.rating,
    required this.likeCount,
    required this.commentCount,
    required this.timeAgo,
    this.liked = false,
  });
}

// ── Screen ─────────────────────────────────────────────────────────────

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  // Placeholder posts — swap for a StreamBuilder<List<Post>> from Firestore
  final List<_Post> _posts = [
    _Post(
      id: '1',
      username: 'alex_raves',
      initials: 'A',
      caption: 'Fabric last night was absolutely mental. The sound system on floor 1 is on another level. Didn\'t leave until 9am 😅',
      venueTag: 'Fabric',
      rating: 4.5,
      likeCount: 24,
      commentCount: 5,
      timeAgo: '2h ago',
    ),
    _Post(
      id: '2',
      username: 'mia_nightlife',
      initials: 'M',
      caption: 'First time at Printworks and honestly I\'m obsessed. The industrial vibe is unreal. Already planning the next one.',
      venueTag: 'Printworks',
      eventTag: 'Junction 2 Indoor',
      rating: 5,
      likeCount: 61,
      commentCount: 12,
      timeAgo: '5h ago',
    ),
    _Post(
      id: '3',
      username: 'dan_techno',
      initials: 'D',
      caption: 'Solid night at XOYO. DJ set was fire but got a bit too packed around midnight.',
      venueTag: 'XOYO',
      rating: 3.5,
      likeCount: 9,
      commentCount: 2,
      timeAgo: '1d ago',
    ),
    _Post(
      id: '4',
      username: 'priya_b',
      initials: 'P',
      caption: 'EGG London terrace in summer hits different. Perfect warm-up before the main room.',
      venueTag: 'EGG London',
      rating: 4,
      likeCount: 37,
      commentCount: 8,
      timeAgo: '2d ago',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 1) return;
          Navigator.of(context).pop();
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
                    // + Log a night out button
                    GestureDetector(
                      onTap: () {
                        // TODO: navigate to CreatePostScreen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Post logging — coming soon!')),
                        );
                      },
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

              // Feed
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) => _postCard(_posts[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _postCard(_Post post) {
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
          // Header — avatar, name, time
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: kAccent.withOpacity(0.35),
                  child: Text(
                    post.initials,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(post.timeAgo, style: const TextStyle(color: kMuted, fontSize: 11)),
                    ],
                  ),
                ),
                if (post.rating != null) _ratingBadge(post.rating!),
              ],
            ),
          ),

          // Venue / event tags
          if (post.venueTag != null || post.eventTag != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Wrap(
                spacing: 8,
                children: [
                  if (post.venueTag != null)
                    _tag(Icons.location_on, post.venueTag!),
                  if (post.eventTag != null)
                    _tag(Icons.confirmation_number, post.eventTag!),
                ],
              ),
            ),

          // Caption
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Text(
              post.caption,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
            ),
          ),

          // TODO: image — add Image.network(post.imageUrl) here when real data exists

          // Divider
          Divider(height: 1, color: kBorder),

          // Actions — like + comment
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _actionButton(
                  icon: post.liked ? Icons.favorite : Icons.favorite_border,
                  label: '${post.likeCount}',
                  color: post.liked ? const Color(0xFFFF6B8A) : kMuted,
                  onTap: () {
                    setState(() {
                      post.liked = !post.liked;
                      post.likeCount += post.liked ? 1 : -1;
                    });
                  },
                ),
                const SizedBox(width: 4),
                _actionButton(
                  icon: Icons.chat_bubble_outline,
                  label: '${post.commentCount}',
                  color: kMuted,
                  onTap: () {
                    // TODO: navigate to CommentScreen(postId: post.id)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Comments — coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 18),
      label: Text(label, style: TextStyle(color: color, fontSize: 13)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }
}