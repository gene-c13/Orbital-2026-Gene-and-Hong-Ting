class Event {
  final String name;
  final String venue;
  final String dj;
  final String artistBio;
  final String time;
  final String price;
  final String crowdLevel; // 'High', 'Medium', or 'Low'
  final List<String> genres;
  final bool hasGuestlist;
  final String id;         // Firestore document ID
  final String date;       // date in YYYY-MM-DD format for filtering
  final String ticketUrl;  // link to buy tickets (empty = no link)
  final String description; //event description

  const Event({
    required this.name,
    required this.venue,
    required this.dj,
    required this.time,
    required this.price,
    required this.crowdLevel,
    required this.genres,
    this.hasGuestlist = false,
    this.id = '',
    this.date = '',
    this.ticketUrl = '',
    this.artistBio = '',
    this.description = '',
  });

  // fromFirestore() converts raw Firestore data into a clean Event object
  // Called like: Event.fromFirestore(documentData, documentId)
  factory Event.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Event(
      id: documentId,
      name: data['name'] ?? 'Unknown Event',
      venue: data['venue'] ?? 'Unknown Venue',
      dj: data['dj'] ?? 'Unknown DJ',
      time: data['time'] ?? 'TBC',
      price: data['price'] ?? 'TBC',
      // Firestore stores crowd_level (snake_case), Dart uses crowdLevel (camelCase)
      crowdLevel: data['crowd_level'] ?? 'Low',
      // Firestore stores has_guestlist, Dart uses hasGuestlist
      hasGuestlist: data['has_guestlist'] ?? false,
      // Firestore arrays come back as List<dynamic> — cast each item to String
      genres: List<String>.from(data['genres'] ?? []),
      date: data['date'] ?? '',
      ticketUrl: data['ticket_url'] ?? '',
      artistBio: data['artist_bio'] ?? '',     // ← new
      description: data['description'] ?? '',
    );
  }
}