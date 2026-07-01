import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:after_hours/theme/app_theme.dart';

/// Circular avatar that shows [photoUrl] when it's set, otherwise falls back
/// to the first letter of [displayName].
///
/// Shared so profile screens, friend lists, and (soon) event-card attendee
/// badges all render a user's picture the same way instead of each screen
/// re-implementing the photo-or-initial fallback logic.
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final double radius;
  final double? fontSize;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    required this.displayName,
    this.photoUrl,
    this.radius = 24,
    this.fontSize,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? kAccent.withValues(alpha: 0.25),
      backgroundImage: hasPhoto ? CachedNetworkImageProvider(photoUrl!) : null,
      child: hasPhoto
          ? null
          : Text(
              initial,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize ?? radius * 0.75,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
