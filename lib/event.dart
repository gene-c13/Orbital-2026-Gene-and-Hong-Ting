class Event {
  final String name;
  final String venue;
  final String dj;
  final String time;
  final String price;
  final String crowdLevel; // 'High', 'Medium', or 'Low'
  final List<String> genres;
  final bool hasGuestlist;

  const Event({
    required this.name,
    required this.venue,
    required this.dj,
    required this.time,
    required this.price,
    required this.crowdLevel,
    required this.genres,
    this.hasGuestlist = false,
  });
}