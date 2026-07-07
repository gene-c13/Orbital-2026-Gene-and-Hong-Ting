import 'package:flutter_test/flutter_test.dart';
import 'package:after_hours/models/event.dart';

// Mirrors the private _matches() method in events_screen.dart, so this test
// can call it directly without needing to build the whole screen.
bool matches(Event e, String q) {
  final query = q.toLowerCase().trim();
  return e.name.toLowerCase().contains(query)
      || e.venue.toLowerCase().contains(query)
      || e.dj.toLowerCase().contains(query)
      || e.genres.any((g) => g.toLowerCase().contains(query));
}

Event _event({
  String name = 'Test Night',
  String venue = 'Zouk',
  String dj = 'DJ Test',
  List<String> genres = const [],
}) {
  return Event(
    name: name,
    venue: venue,
    dj: dj,
    time: '10:00 PM',
    price: '\$20',
    crowdLevel: 'Medium',
    genres: genres,
  );
}

void main() {
  test('matches when query appears in the venue name', () {
    final event = _event(venue: 'Zouk Mainroom');
    expect(matches(event, 'zouk'), true);
  });

  test('matches when query appears in the DJ name', () {
    final event = _event(dj: 'Ghetto Kraft');
    expect(matches(event, 'kraft'), true);
  });

  test('matches when query appears in a genre tag', () {
    final event = _event(genres: ['House', 'Techno']);
    expect(matches(event, 'techno'), true);
  });

  test('matching is case insensitive', () {
    final event = _event(venue: 'Marquee');
    expect(matches(event, 'MARQUEE'), true);
  });

  test('leading and trailing spaces in the query are ignored', () {
    final event = _event(name: 'Neon Nights');
    expect(matches(event, '  neon  '), true);
  });

  test('does not match when query appears in none of the fields', () {
    final event = _event(name: 'Neon Nights', venue: 'Zouk', dj: 'DJ Test', genres: ['House']);
    expect(matches(event, 'jungle'), false);
  });

  test('empty query matches everything', () {
    final event = _event();
    expect(matches(event, ''), true);
  });
}
