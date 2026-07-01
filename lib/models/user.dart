class AppUser {
  final String uid;
  final String username;
  final String displayName;
  final String photoUrl;
  final String favouriteVenue;
  final String favouriteGenre;
  final List<String> clubsVisited;
  final num hoursThisMonth;
  final int eventsThisMonth;
  final int totalEvents;
  final int pukeCount;

  const AppUser({
    required this.uid,
    required this.username,
    this.displayName = '',
    this.photoUrl = '',
    this.favouriteVenue = '',
    this.favouriteGenre = '',
    this.clubsVisited = const [],
    this.hoursThisMonth = 0,
    this.eventsThisMonth = 0,
    this.totalEvents = 0,
    this.pukeCount = 0,
  });

  /// Display name to show, falling back to [username].
  ///
  /// `display_name` is only written to Firestore once a user opens "Edit
  /// Profile" and saves — registration only sets `username`. So anyone who
  /// hasn't edited their profile yet has no display_name, which matters a lot
  /// once we're rendering *other* users (attendee lists, chat), since we
  /// can't fall back to FirebaseAuth's displayName the way profile_screen
  /// does for the current user.
  String get name => displayName.isNotEmpty ? displayName : username;

  factory AppUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      username: data['username'] ?? '',
      displayName: data['display_name'] ?? '',
      photoUrl: data['photo_url'] ?? '',
      favouriteVenue: data['favourite_venue'] ?? '',
      favouriteGenre: data['favourite_genre'] ?? '',
      clubsVisited: List<String>.from(data['clubs_visited'] ?? []),
      hoursThisMonth: (data['hours_this_month'] ?? 0) as num,
      eventsThisMonth: ((data['events_this_month'] ?? 0) as num).toInt(),
      totalEvents: ((data['total_events'] ?? 0) as num).toInt(),
      pukeCount: ((data['puke_count'] ?? 0) as num).toInt(),
    );
  }
}
