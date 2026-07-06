import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/services/auth_service.dart';
import 'package:after_hours/screens/events/events_screen.dart';
import 'package:after_hours/screens/auth/register_screen.dart';
import 'package:after_hours/screens/auth/email_verification_screen.dart';
import 'package:after_hours/screens/auth/username_setup_screen.dart';
import 'package:after_hours/widgets/primary_button.dart';

class LoginScreen extends StatefulWidget { //stateful to track state (error?user typing?)
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState(); //instruction: set state of widget to LoginScreenState 
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitting = false;

  Future<void> _signIn() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final auth = AuthService();
      final user = await auth.signIn(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (!mounted) return;

      if (user != null && !user.emailVerified) {
        await auth.sendVerification();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
        );
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => auth.hasDisplayName ? const EventsScreen() : const UsernameSetupScreen(),
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() { //release memory the controllers were holding ie. prevent memory leak
    emailController.dispose();
    passwordController.dispose();
    super.dispose(); //calls parent class' cleanup, always goes last.
  }

  // both fields share the same look, so the decoration lives in one place
  // (same approach as _textField in register_screen.dart)
  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboard = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    bool obscure = false,
    Widget? suffix,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      textInputAction: action,
      obscureText: obscure,
      onSubmitted: onSubmitted,
      cursorColor: Colors.white,
      selectionControls: materialTextSelectionControls,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0x80FFFFFF)),
        filled: true,
        fillColor: const Color(0x26FFFFFF),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) { //frontend: building the UI layout
    return Scaffold( //scaffold is the standard full sceen container
      body: Container(
        width: double.infinity, //as wide as possible ie. fill up screen
        height: double.infinity,
        decoration: kBgDecorationAuth,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final logoHeight = (constraints.maxHeight * 0.55).clamp(140.0, 280.0);
            return SingleChildScrollView( //lets content scroll if keyboard pushes things up
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
              Container( //this is the semi-transparent card that holds all the text boxes
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
                      _textField(
                        controller: emailController, //the TextField class accpets controller as its paramater
                        hint: 'your@email.com',
                        keyboard: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      const Text('Password',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _textField(
                        controller: passwordController,
                        hint: '••••••••',
                        obscure: _obscurePassword,
                        action: TextInputAction.done,
                        onSubmitted: (_) => _signIn(),
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: const Color(0x80FFFFFF),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: 'Sign In',
                        onPressed: _submitting ? null : _signIn,
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).push( //push and not pushreplacement so user can go back to login screen
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
