import 'package:flutter_test/flutter_test.dart';
import 'package:after_hours/models/event.dart';

// Imports the REAL Event model. If someone renames a Firestore field (e.g.
// 'crowd_level'), the default-value test below is what catches it.

void main() {
  group('Event.fromFirestore', () {
    test('reads values when the map is fully populated', () {
      final event = Event.fromFirestore({
        'name':        'Neon Nights',
        'venue':       'Cherry',
        'dj':          'DJ Test',
        'crowd_level': 'High',
        'genres':      ['House', 'Techno'],
      }, 'doc1');

      expect(event.id, 'doc1');
      expect(event.name, 'Neon Nights');
      expect(event.crowdLevel, 'High');
      expect(event.genres, ['House', 'Techno']);
    });

    test('applies fallback defaults when keys are missing', () {
      final event = Event.fromFirestore({}, 'doc2');

      expect(event.name, 'Unknown Event');
      expect(event.venue, 'Unknown Venue');
      expect(event.dj, 'Unknown DJ');
      expect(event.time, 'TBC');
      expect(event.price, 'TBC');
      expect(event.crowdLevel, 'Low');
      expect(event.genres, isEmpty);
    });

    test('falls back to an empty list when genres is the wrong type', () {
      final event = Event.fromFirestore({'genres': 'House'}, 'doc3');
      expect(event.genres, isEmpty);
    });

    test('falls back to TBC when price arrives as a number, not a string', () {
      final event = Event.fromFirestore({'price': 20}, 'doc4');
      expect(event.price, 'TBC');
    });

    test('falls back to Low when crowd_level arrives as a number', () {
      final event = Event.fromFirestore({'crowd_level': 3}, 'doc5');
      expect(event.crowdLevel, 'Low');
    });
  });
}
