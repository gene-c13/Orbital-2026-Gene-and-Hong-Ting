import 'package:cloud_firestore/cloud_firestore.dart';
// this model defines profile data and instruct how to convert Firestore doc 
//into a usable AppUser object (just like in Events.dart)
class AppUser {
  final String uid;
  final String username;
  final String displayName;
  final String photoUrl;
  final String favouriteVenue;
  final String favouriteGenre;
  final String bio;
  final List<String> clubsVisited;
  final num hoursThisMonth;
  final int eventsThisMonth;
  final int totalEvents;
  final int pukeCount;
  final bool isPublic;
  final Timestamp? notificationsSeenAt;
  

  const AppUser({
    required this.uid,
    required this.username,
    this.displayName = '',
    this.photoUrl = '',
    this.favouriteVenue = '',
    this.favouriteGenre = '',
    this.clubsVisited = const [], //means empty list that never changes
    this.hoursThisMonth = 0,
    this.eventsThisMonth = 0,
    this.totalEvents = 0,
    this.pukeCount = 0,
    this.isPublic = true,
    this.bio = '',
    this.notificationsSeenAt,
  });


  // this is a getter (function that looks like a field), auto called by user.name
  //user.name will show displayName else username
  String get name => displayName.isNotEmpty ? displayName : username;

  // the month the monthly stats belong to, e.g. "2026-07"
  // stored on the user doc so we know when the counters are stale
  static String get currentMonthKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

//construct AppUser object from the dictionary
// that Firestore returns via await firestore.collection("users").doc(id).get
  factory AppUser.fromFirestore(Map<String, dynamic> data, String uid) {
    // counters from a previous month are stale, so read them as 0
    final isCurrentMonth = data['stats_month'] == currentMonthKey;
    return AppUser(
      uid: uid,
      username: data['username'] ?? '',
      displayName: data['display_name'] ?? '',
      photoUrl: data['photo_url'] ?? '',
      favouriteVenue: data['favourite_venue'] ?? '',
      favouriteGenre: data['favourite_genre'] ?? '',
      clubsVisited: List<String>.from(data['clubs_visited'] ?? []),
      hoursThisMonth: isCurrentMonth ? data['hours_this_month'] ?? 0 : 0,
      eventsThisMonth: isCurrentMonth ? data['events_this_month'] ?? 0 : 0,
      totalEvents: data['total_events'] ?? 0,
      pukeCount: data['puke_count'] ?? 0,
      isPublic: data['is_public'] as bool? ?? true,
      bio: data['bio'] ?? '',
      notificationsSeenAt: data['notifications_seen_at'] as Timestamp?,
    );
  }
}
