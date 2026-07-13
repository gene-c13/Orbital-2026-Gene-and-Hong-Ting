import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/firebase_options.dart';
import 'package:after_hours/screens/auth/login_screen.dart';
import 'package:after_hours/screens/auth/email_verification_screen.dart';
import 'package:after_hours/screens/auth/username_setup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:after_hours/screens/events/events_screen.dart';
import 'package:after_hours/widgets/notification_toast_listener.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AfterHoursApp());
}

class AfterHoursApp extends StatelessWidget {
  const AfterHoursApp({super.key});

  @override
  Widget build(BuildContext context) {
    // NotificationToastListener wraps the whole MaterialApp, not just
    // home:, because goToTab() calls pushAndRemoveUntil with a predicate
    // that always returns false — that wipes every route in the Navigator,
    // including whatever home: originally built. Only widgets sitting
    // ABOVE MaterialApp (outside the Navigator entirely) survive that.
    return NotificationToastListener(
      child: MaterialApp( //this is Flutter's top level wrapper that enables navitagtion, theming and routing
        title: 'After Hours',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
        theme: ThemeData.dark().copyWith( //copyWith means overriding the dark theme with specific parts you want
          scaffoldBackgroundColor: kBg,
          textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
          colorScheme: const ColorScheme.dark(
            primary: kAccent,
            secondary: kPink,
            surface: kBg,
          ),
          snackBarTheme: const SnackBarThemeData( //set default color for snackBar which are notifications like "Login failed"
            backgroundColor: Color(0xFF1A0A3B),
            contentTextStyle: TextStyle(color: Colors.white),
          ),
        ),
        home: StreamBuilder<User?>( //streambuilder is a widget that listens to a stream, user? means either a user or null
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasData) {
              final user = snapshot.data!;
              // a user who killed the app before verifying should still be sent to the
              // verification screen, not straight into the app
              if (!user.emailVerified) return const EmailVerificationScreen();
              // a user who completed verification but not username setup goes there next
              if ((user.displayName ?? '').isEmpty) return const UsernameSetupScreen();
              return const EventsScreen(); //if logged in and fully set up, show events
            }
            return const LoginScreen(); //if not logged in, show login screen
          },
        ),
      ),
    );
  }
}
