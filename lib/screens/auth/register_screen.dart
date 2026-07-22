import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/services/auth_service.dart';
import 'package:after_hours/screens/auth/email_verification_screen.dart';
import 'package:after_hours/widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();
  final _usernameController = TextEditingController();

  bool _showPassword = false; 
  bool _showConfirm  = false;
  bool _submitting   = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  bool get _hasMinLength  => _passwordController.text.length >= 8; //get declares a getter not a regular variable, no need for (), 
  bool get _hasUppercase  => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber     => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial    => _passwordController.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'));
  bool get _validUsername => RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(_usernameController.text.trim());

  int get _strength {
    final p = _passwordController.text;
    if (p.isEmpty) return 0;
    var score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase) score++;
    if (_hasNumber) score++;
    if (_hasSpecial) score++;
    if (score <= 1) return 1;
    if (score <= 2) return 2;
    return 3;
  }

  Color get _strengthColor {
    switch (_strength) {
      case 1: return const Color(0xFFFF4D4D);
      case 2: return const Color(0xFFFFB547);
      case 3: return const Color(0xFF4CAF50);
      default: return Colors.transparent;
    }
  }

  String get _strengthLabel {
    switch (_strength) {
      case 1: return 'Weak';
      case 2: return 'Medium';
      case 3: return 'Strong';
      default: return '';
    }
  }

  Future<void> _submit() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm  = _confirmController.text;
    final username = _usernameController.text.trim().toLowerCase();

    if (email.isEmpty || password.isEmpty || username.isEmpty) { _snack('Please fill in all fields.'); return; }
    if (!_validUsername) { _snack('Username must be 3–20 chars, letters/numbers/underscores only.'); return; }
    if (!_hasMinLength) { _snack('Password must be at least 8 characters.'); return; }
    if (!_hasUppercase) { _snack('Password needs at least one uppercase letter.'); return; }
    if (!_hasNumber)    { _snack('Password needs at least one number.'); return; }
    if (!_hasSpecial)   { _snack('Password needs at least one special character (!@#\$%...).'); return; }
    if (password != confirm) { _snack("Passwords don't match."); return; }

    setState(() => _submitting = true);

    try {
      await AuthService().register(
        email: email,
        password: password,
        username: username,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EmailVerificationScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Something went wrong.';
      if (e.code == 'email-already-in-use') { message = 'That email already has an account.'; }
      else if (e.code == 'invalid-email')   { message = "That email doesn't look right."; }
      _snack(message);
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('username_taken')) {
        _snack('That username is already taken.');
      } else {
        _snack('Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: kBgDecorationAuth,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Image.asset('assets/images/after_hours_logo.png', height: 200),
              const SizedBox(height: 4),
              const Text(
                'LESS PLANNING. MORE PARTYING.',
                style: TextStyle(fontSize: 13, color: Color(0xCCB14EFF), letterSpacing: 2),
              ),
              const SizedBox(height: 28),

              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Username'),
                    const SizedBox(height: 8),
                    _textField(
                      controller: _usernameController,
                      hint: 'e.g. hongting_99',
                      action: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 6),
                    if (_usernameController.text.isNotEmpty)
                      _req('3–20 characters, letters/numbers/underscores only', _validUsername),
                    const SizedBox(height: 16),

                    _label('Email'),
                    const SizedBox(height: 8),
                    _textField(
                      controller: _emailController,
                      hint: 'your@email.com',
                      keyboard: TextInputType.emailAddress,
                      action: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    _label('Password'),
                    const SizedBox(height: 8),
                    _textField(
                      controller: _passwordController,
                      hint: '••••••••',
                      obscure: !_showPassword,
                      action: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      suffix: _eyeIcon(_showPassword, () => setState(() => _showPassword = !_showPassword)),
                    ),

                    if (_passwordController.text.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _strengthBar(),
                      const SizedBox(height: 6),
                      _requirements(),
                    ],
                    const SizedBox(height: 16),

                    _label('Confirm password'),
                    const SizedBox(height: 8),
                    _textField(
                      controller: _confirmController,
                      hint: '••••••••',
                      obscure: !_showConfirm,
                      action: TextInputAction.done,
                      onChanged: (_) => setState(() {}),
                      suffix: _eyeIcon(_showConfirm, () => setState(() => _showConfirm = !_showConfirm)),
                      onSubmitted: (_) => _submit(),
                    ),

                    if (_confirmController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: _req('Passwords match',
                            _passwordController.text == _confirmController.text),
                      ),

                    const SizedBox(height: 24),

                    PrimaryButton(
                      label: 'Create Account',
                      onPressed: _submit,
                      loading: _submitting,
                    ),
                    const SizedBox(height: 4),

                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Already have an account? Sign in',
                          style: TextStyle(color: Color(0xCCB14EFF)),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboard = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    bool obscure = false,
    Widget? suffix,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      textInputAction: action,
      obscureText: obscure,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
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

  Widget _eyeIcon(bool visible, VoidCallback onTap) => IconButton(
    icon: Icon(
      visible ? Icons.visibility_off : Icons.visibility,
      color: kMuted,
      size: 20,
    ),
    onPressed: onTap,
  );

  Widget _strengthBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _strength / 3,
            backgroundColor: const Color(0x33FFFFFF),
            valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _strengthLabel,
          style: TextStyle(color: _strengthColor, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _requirements() {
    return Column(
      children: [
        _req('At least 8 characters', _hasMinLength),
        _req('One uppercase letter (A–Z)', _hasUppercase),
        _req('One number (0–9)', _hasNumber),
        _req('One special character (!@#\$%...)', _hasSpecial),
      ],
    );
  }

  Widget _req(String label, bool met) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            size: 13,
            color: met ? const Color(0xFF4CAF50) : const Color(0x55FFFFFF),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: met ? const Color(0xFF4CAF50) : const Color(0x88FFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}
