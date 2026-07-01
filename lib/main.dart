import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/firebase_options.dart';
import 'package:after_hours/screens/auth/login_screen.dart';

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
    return MaterialApp( //this is Flutter's top level wrapper that enables navitagtion, theming and routing
      title: 'After Hours',
      debugShowCheckedModeBanner: false,
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
      home: const LoginScreen(),
    );
  }
}
