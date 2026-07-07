import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/screens/social/create_post_screen.dart';
import 'package:after_hours/widgets/navigation_helper.dart';
import 'package:after_hours/screens/social/comments_sheet.dart';
import 'package:after_hours/screens/social/user_search_screen.dart';
import 'package:after_hours/services/post_service.dart';
import 'package:after_hours/widgets/user_avatar.dart';
import 'package:after_hours/widgets/tap_to_profile.dart';
import 'package:after_hours/utils/time_format.dart';
import 'dart:async';
import 'package:after_hours/services/auth_service.dart';
import 'package:after_hours/screens/social/friend_requests_screen.dart';

class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  List<QueryDocumentSnapshot> _visibleDocs = [];
  String? _currentUid;
  bool _initialLoad = true;
  bool _hasError = false;

  StreamSubscription? _feedSub;

  @override
  void initState() {
    super.initState();
    _currentUid = AuthService().currentUid;
    _subscribeToPosts();
  }

  @override
  void dispose() {
    _feedSub?.cancel();
    super.dispose();
  }

  void _subscribeToPosts() {
    if (_currentUid == null) {
      setState(() { _visibleDocs = []; _initialLoad = false; });
      return;
    }

    _feedSub = PostService().feedStream(_currentUid!).listen(
      (docs) {
        if (mounted) setState(() { _visibleDocs = docs; _initialLoad = false; });
      },
      onError: (e) {
        debugPrint('social feed error: $e');
        if (mounted) setState(() { _hasError = true; _initialLoad = false; });
      },
    );
  }

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
                   IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FriendRequestsScreen()),
                      ),
                      icon: const Icon(Icons.notifications_none, color: Colors.white, size: 22),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const UserSearchScreen()),
                      ),
                      icon: const Icon(Icons.search, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 4),
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
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_initialLoad) {
      return const Center(child: CircularProgressIndicator(color: kAccent, strokeWidth: 2));
    }
    if (_hasError) {
      return const Center(
        child: Text('Something went wrong.', style: TextStyle(color: kMuted)),
      );
    }
    if (_visibleDocs.isEmpty) {
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
      itemCount: _visibleDocs.length,
      itemBuilder: (context, index) {
        final data = _visibleDocs[index].data() as Map<String, dynamic>;
        return _PostCard(postId: _visibleDocs[index].id, data: data);
      },
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
    final uid = AuthService().currentUid ?? '';
    return List<String>.from(widget.data['likes'] ?? []).contains(uid);
  }

  int get _likeCount => (widget.data['likes'] as List?)?.length ?? 0;

  Future<void> _toggleLike() async {
    final uid = AuthService().currentUid;
    if (uid == null) return;
    await PostService().toggleLike(widget.postId, uid, _liked);
  }

  @override
  Widget build(BuildContext context) {
    final data         = widget.data;
    final displayName  = data['display_name'] as String? ?? 'Raver';
    final username     = data['username'] as String? ?? '';
    final caption      = data['caption'] as String? ?? '';
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
      decoration: kCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TapToProfile(
                    uid: data['uid'] as String? ?? '',
                    child: Row(
                      children: [
                        UserAvatar(
                          displayName: displayName,
                          photoUrl: data['photo_url'] as String?,
                          radius: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                              if (username.isNotEmpty)
                                Text('@$username', style: const TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                              Text(timeAgo(ts), style: const TextStyle(color: kDim, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => CommentsSheet(postId: widget.postId),
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
