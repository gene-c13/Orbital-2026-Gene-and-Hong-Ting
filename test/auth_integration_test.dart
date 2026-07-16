import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:after_hours/firebase_options.dart';
import 'package:after_hours/services/auth_service.dart';

// Integration test: this runs the REAL register() against the local Firebase
// emulators, then checks that the right documents were created.
//
// Start the emulators first in another terminal:  firebase emulators:start

void main() {
  const projectId = 'after-hours-87c70';
  final auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;
  final service = AuthService();

  // Runs once, before any test: start Firebase, then point it at the fake
  // local emulators instead of the real project.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await auth.useAuthEmulator('localhost', 9099);
    db.useFirestoreEmulator('localhost', 8080);
  });

  // Runs after every test: wipe the fake data so the test can be run again.
  tearDown(() async {
    await _clearEmulator('localhost:9099',
        '/emulator/v1/projects/$projectId/accounts');
    await _clearEmulator('localhost:8080',
        '/emulator/v1/projects/$projectId/databases/(default)/documents');
  });

  test('sign up creates both the user and username documents', () async {
    await service.register(
      email: 'gene@test.com',
      password: 'password123',
      username: 'gene',
    );

    final uid = auth.currentUser!.uid;
    final userDoc = await db.collection('users').doc(uid).get();
    final nameDoc = await db.collection('usernames').doc('gene').get();

    expect(userDoc.exists, true);         // the profile record exists
    expect(nameDoc.exists, true);         // the username reservation exists
    expect(nameDoc.data()!['uid'], uid);  // and it points back to this user
  });
}

// Tells an emulator to delete all of its data by calling its "clear" endpoint.
Future<void> _clearEmulator(String hostPort, String path) async {
  final client = HttpClient();
  final request = await client.deleteUrl(Uri.parse('http://$hostPort$path'));
  await request.close();
  client.close();
}
