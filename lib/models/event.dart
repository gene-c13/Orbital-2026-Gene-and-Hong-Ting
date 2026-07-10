class Event {
  final String id;
  final String name;
  final String venue;
  final String dj;
  final String artistBio;
  final String time;
  final String price;
  final String crowdLevel;
  final List<String> genres;
  final bool hasGuestlist;
  final String date;
  final String bookingUrl;
  final String description;
  final String imageUrl;

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
    this.bookingUrl = '',
    this.artistBio = '',
    this.description = '',
    this.imageUrl = '',
  });

  //Create an Event object using the results of Firestore (which are always dictionaries)
  factory Event.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Event(
      id:           documentId,
      name:         data['name']         ?? 'Unknown Event', //construct Event where name is data[name], if null:Unknown Event
      venue:        data['venue']        ?? 'Unknown Venue',
      dj:           data['dj']           ?? 'Unknown DJ',
      time:         data['time']         ?? 'TBC',
      price:        data['price']        ?? 'TBC',
      crowdLevel:   data['crowd_level']  ?? 'Low',
      hasGuestlist: data['has_guestlist'] ?? false,
      genres:       List<String>.from(data['genres'] ?? []),
      date:         data['date']         ?? '',
      bookingUrl:    data['booking_url']   ?? '',
      artistBio:    data['artist_bio']   ?? '',
      description:  data['description']  ?? '',
      imageUrl: data['image_url'] ?? '',
    );
  }
}
