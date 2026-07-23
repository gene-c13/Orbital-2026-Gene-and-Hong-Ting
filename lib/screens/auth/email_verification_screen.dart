import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/services/auth_service.dart';
import 'package:after_hours/screens/events/events_screen.dart';
import 'package:after_hours/screens/auth/profile_setup_screen.dart';
import 'package:after_hours/screens/auth/login_screen.dart';
import 'package:after_hours/widgets/primary_button.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _pollTimer;
  bool   _resending       = false;
  bool   _checking        = false;
  int    _resendCooldown  = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkVerified(auto: true)); //auto check every 5s
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerified({bool auto = false}) async {
    if (!auto) setState(() => _checking = true);
    try {
      final auth = AuthService();
      final verified = await auth.checkEmailVerified();
      if (verified && mounted) {
        _pollTimer?.cancel();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => auth.hasDisplayName
                ? const EventsScreen()
                : const ProfileSetupScreen(),
          ),
        );
      }
    } catch (_) {
      // swallow network/token errors so the poll timer keeps running quietly
    } finally {
      if (mounted && !auto) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0) return;
    setState(() => _resending = true);
    try {
      await AuthService().sendVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent!')),
      );
      setState(() => _resendCooldown = 60);
      _cooldownTimer?.cancel();
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() => _resendCooldown--);
        if (_resendCooldown <= 0) t.cancel();
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not resend email.')),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _signOut() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService().currentUser?.email ?? '';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: kBgDecorationAuth,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: SingleChildScrollView(
              child: Column(
                // min instead of the default max — a scroll view has no fixed
                // height, so the column should only take as much space as its
                // children actually need
                mainAxisSize: MainAxisSize.min,
                children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0x22B14EFF),
                    shape: BoxShape.circle,
                    border: Border.all(color: kAccent.withValues(alpha: 0.5), width: 2),
                  ),
                  child: const Icon(Icons.mark_email_unread_outlined, color: kAccent, size: 38),
                ),
                const SizedBox(height: 28),

                const Text(
                  'Verify your email',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                const Text(
                  'We sent a verification link to',
                  style: TextStyle(color: kMuted, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Click the link in the email, then come back here.',
                  style: TextStyle(color: kMuted, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                PrimaryButton(
                  label: "I've verified my email",
                  onPressed: () => _checkVerified(),
                  loading: _checking,
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: (_resending || _resendCooldown > 0) ? null : _resend,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: kAccent.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      disabledForegroundColor: kDim,
                    ),
                    child: _resending
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(color: kAccent, strokeWidth: 2),
                          )
                        : Text(
                            _resendCooldown > 0
                                ? 'Resend in ${_resendCooldown}s'
                                : 'Resend email',
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                TextButton(
                  onPressed: _signOut,
                  child: const Text(
                    'Use a different account',
                    style: TextStyle(color: kDim, fontSize: 13),
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
