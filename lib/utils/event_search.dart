import 'package:after_hours/models/event.dart';

// Does this event match a search query? Checks name, venue, dj and genres,
// case-insensitively, ignoring leading/trailing spaces in the query.
bool matches(Event e, String q) {
  final query = q.toLowerCase().trim();
  return e.name.toLowerCase().contains(query)
      || e.venue.toLowerCase().contains(query)
      || e.dj.toLowerCase().contains(query)
      || e.genres.any((g) => g.toLowerCase().contains(query));
}
