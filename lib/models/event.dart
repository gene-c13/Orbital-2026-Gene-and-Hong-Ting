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
  final String ticketUrl;
  final String description;

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

  factory Event.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Event(
      id:           documentId,
      name:         data['name']         ?? 'Unknown Event',
      venue:        data['venue']        ?? 'Unknown Venue',
      dj:           data['dj']           ?? 'Unknown DJ',
      time:         data['time']         ?? 'TBC',
      price:        data['price']        ?? 'TBC',
      crowdLevel:   data['crowd_level']  ?? 'Low',
      hasGuestlist: data['has_guestlist'] ?? false,
      genres:       List<String>.from(data['genres'] ?? []),
      date:         data['date']         ?? '',
      ticketUrl:    data['ticket_url']   ?? '',
      artistBio:    data['artist_bio']   ?? '',
      description:  data['description']  ?? '',
    );
  }
}
