import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/screens/social/comments_sheet.dart';
import 'package:after_hours/services/post_service.dart';
import 'package:after_hours/services/auth_service.dart';
import 'package:after_hours/widgets/user_avatar.dart';
import 'package:after_hours/widgets/tap_to_profile.dart';
import 'package:after_hours/utils/time_format.dart';

class PostCard extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> data;

  const PostCard({super.key, required this.postId, required this.data});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
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

  Widget _pukeBadge() => const Text('🤮', style: TextStyle(fontSize: 13));

  Widget _ratingBadge(double rating) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: kAccent, size: 12),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: kMuted, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}