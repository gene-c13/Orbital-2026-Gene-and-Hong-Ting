import 'package:flutter_test/flutter_test.dart';
import 'package:after_hours/models/user.dart';

// Unlike date/hours/search, these tests import the REAL AppUser class and
// call it directly, so they actually guard the code the app runs.

void main() {
  group('AppUser.name getter', () {
    test('uses displayName when it is set', () {
      const user = AppUser(uid: 'u1', username: 'partyanimal', displayName: 'Gene');
      expect(user.name, 'Gene');
    });

    test('falls back to username when displayName is empty', () {
      const user = AppUser(uid: 'u1', username: 'partyanimal', displayName: '');
      expect(user.name, 'partyanimal');
    });
  });

  group('AppUser.fromFirestore', () {
    test('reads every field when the map is fully populated', () {
      final user = AppUser.fromFirestore({
        'username':         'gene',
        'display_name':     'Gene C',
        'photo_url':        'http://img/1.jpg',
        'favourite_venue':  'Zouk',
        'favourite_genre':  'Techno',
        'clubs_visited':    ['Zouk', 'Cherry'],
        'hours_this_month': 12,
        'events_this_month': 3,
        'total_events':     20,
        'puke_count':       1,
        'is_public':        false,
        'bio':              'here for the music',
      }, 'u1');

      expect(user.uid, 'u1');
      expect(user.displayName, 'Gene C');
      expect(user.clubsVisited, ['Zouk', 'Cherry']);
      expect(user.eventsThisMonth, 3);
      expect(user.isPublic, false);
    });

    test('applies defaults when keys are missing', () {
      final user = AppUser.fromFirestore({}, 'u2');

      expect(user.username, '');
      expect(user.displayName, '');
      expect(user.clubsVisited, isEmpty);
      expect(user.hoursThisMonth, 0);
      expect(user.pukeCount, 0);
      expect(user.isPublic, true); // accounts are public unless set otherwise
    });
  });
}
