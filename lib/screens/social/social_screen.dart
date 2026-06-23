import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/screens/social/create_post_screen.dart';
import 'package:after_hours/widgets/navigation_helper.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: buildNavBar(1, (i) { if (i != 1) goToTab(context, i); }),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: kBgDecoration,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'SOCIAL',
                      style: kNectarine(size: 32, letterSpacing: 3),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: kAccent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 17),
                            SizedBox(width: 5),
                            Text(
                              'Log night',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: kBorder),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .orderBy('created_at', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: kAccent, strokeWidth: 2));
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Something went wrong.', style: TextStyle(color: kMuted)),
                      );
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_camera_outlined, color: kDim, size: 56),
                            const SizedBox(height: 18),
                            const Text(
                              'No posts yet.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('Be the first to log a night.', style: TextStyle(color: kDim, fontSize: 13)),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        return _PostCard(postId: docs[index].id, data: data);
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
    return List<String>.from(widget.data['likes'] ?? []).contains(uid);
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
    final imageUrl     = (data['image_url'] as String?)?.trim() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: kAccent.withValues(alpha: 0.3),
                  child: Text(
                    username[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      Text(_timeAgo(ts), style: const TextStyle(color: kDim, fontSize: 11)),
                    ],
                  ),
                ),
                if (puked) _pukeBadge(),
                if (rating != null) _ratingBadge(rating),
              ],
            ),
          ),

          if (venueTag.isNotEmpty || eventTag.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Wrap(
                spacing: 8,
                children: [
                  if (venueTag.isNotEmpty) _tag(Icons.location_on, venueTag),
                  if (eventTag.isNotEmpty) _tag(Icons.confirmation_number, eventTag),
                ],
              ),
            ),

          if (startTime != null || hoursOut != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: kDim, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    [
                      if (startTime != null && endTime != null) '$startTime - $endTime',
                      if (hoursOut != null) '${hoursOut.toStringAsFixed(1)}h out',
                    ].join('  ·  '),
                    style: const TextStyle(color: kDim, fontSize: 12),
                  ),
                ],
              ),
            ),

          if (imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: 320,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: kSurface,
                    highlightColor: kBorder,
                    child: Container(width: double.infinity, height: 320, color: kSurface),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: double.infinity,
                    height: 320,
                    color: kSurface,
                    child: const Icon(Icons.broken_image_outlined, color: kDim),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Text(caption, style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
          ),

          const Divider(height: 1, color: kBorder),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _toggleLike,
                  icon: Icon(
                    _liked ? Icons.favorite : Icons.favorite_border,
                    color: _liked ? kPink : kDim,
                    size: 18,
                  ),
                  label: Text(
                    '$_likeCount',
                    style: TextStyle(
                      color: _liked ? kPink : kDim,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                ),
                TextButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Comments coming soon!')),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, color: kDim, size: 18),
                  label: Text(
                    '$commentCount',
                    style: const TextStyle(color: kDim, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: const Text('🤮', style: TextStyle(fontSize: 13)),
    );
  }

  Widget _ratingBadge(double rating) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: kAccent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kAccent.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: kAccent, size: 13),
          const SizedBox(width: 3),
          Text(
            rating % 1 == 0 ? '${rating.toInt()}' : '$rating',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _tag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kAccent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kAccent, size: 12),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
