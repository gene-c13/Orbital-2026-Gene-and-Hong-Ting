import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/screens/events/events_screen.dart';
import 'package:after_hours/screens/auth/register_screen.dart';
import 'package:after_hours/screens/auth/email_verification_screen.dart';
import 'package:after_hours/screens/auth/username_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> _signIn() async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (!mounted) return;

      final user = credential.user;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
        );
        return;
      }

      final hasName = (user?.displayName ?? '').isNotEmpty;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => hasName ? const EventsScreen() : const UsernameSetupScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Login failed.';
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Incorrect email or password.';
      } else if (e.code == 'invalid-email') {
        message = "That email doesn't look right.";
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Try again later.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: kBgDecorationAuth,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final logoHeight = (constraints.maxHeight * 0.55).clamp(140.0, 280.0);
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
              child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
              Image.asset('assets/images/after_hours_logo.png', height: logoHeight),
              const Text(
                'LESS PLANNING. MORE PARTYING.',
                style: TextStyle(fontSize: 13, color: Color(0xCCB14EFF), letterSpacing: 2),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0x44B14EFF)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x559D4EDD), blurRadius: 40, spreadRadius: 2),
                  ],
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionTheme: const TextSelectionThemeData(
                      selectionColor: Color(0x55B14EFF),
                      selectionHandleColor: kAccent,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Email',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        cursorColor: Colors.white,
                        selectionControls: materialTextSelectionControls,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'your@email.com',
                          hintStyle: const TextStyle(color: Color(0x80FFFFFF)),
                          filled: true,
                          fillColor: const Color(0x26FFFFFF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Password',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        cursorColor: Colors.white,
                        selectionControls: materialTextSelectionControls,
                        onSubmitted: (_) => _signIn(),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          hintStyle: const TextStyle(color: Color(0x80FFFFFF)),
                          filled: true,
                          fillColor: const Color(0x26FFFFFF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: Container(
                          decoration: kPrimaryButtonDecoration,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _signIn,
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          ),
                          child: const Text(
                            "Don't have an account? Sign up",
                            style: TextStyle(color: Color(0xCCB14EFF)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
                    ],
                  ),
            );
          },
        ),
      ),
    );
  }
}
