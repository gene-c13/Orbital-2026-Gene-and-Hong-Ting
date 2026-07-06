import 'package:flutter/material.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/services/auth_service.dart';
import 'package:after_hours/screens/events/events_screen.dart';
import 'package:after_hours/widgets/app_text_field.dart';
import 'package:after_hours/widgets/genre_picker.dart';
import 'package:after_hours/widgets/primary_button.dart';

class UsernameSetupScreen extends StatefulWidget {
  const UsernameSetupScreen({super.key});

  @override
  State<UsernameSetupScreen> createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends State<UsernameSetupScreen> {
  final _nameController  = TextEditingController();
  final _venueController = TextEditingController();

  String? _selectedGenre;
  bool    _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name  = _nameController.text.trim();
    final venue = _venueController.text.trim();

    if (name.isEmpty)    { _snack('Please enter your name.'); return; }
    if (name.length < 2) { _snack('Name must be at least 2 characters.'); return; }

    setState(() => _submitting = true);

    try {
      await AuthService().completeProfileSetup(
        displayName: name,
        favouriteVenue: venue,
        favouriteGenre: _selectedGenre,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EventsScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('no_user')) {
        _snack('Session expired — please sign in again.');
      } else {
        _snack('Failed to save: $e');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _showGenrePicker() {
    showGenrePicker(context, _selectedGenre, (genre) {
      setState(() => _selectedGenre = genre);
    });
  }

  @override
  Widget build(BuildContext context) {
    final nameReady = _nameController.text.trim().length >= 2;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: kBgDecorationAuth,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Set up your\nprofile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tell us a bit about yourself.',
                  style: TextStyle(color: kMuted, fontSize: 15),
                ),
                const SizedBox(height: 36),

                _fieldLabel('Your name *'),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _nameController,
                  hint: 'e.g. Alex',
                  icon: Icons.person_outline,
                  capitalization: TextCapitalization.words,
                  action: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),

                _fieldLabel('Favourite venue'),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _venueController,
                  hint: 'e.g. Fabric, Printworks...',
                  icon: Icons.location_on_outlined,
                  action: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 20),

                _fieldLabel('Favourite music genre'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showGenrePicker,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
                    decoration: BoxDecoration(
                      color: kSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x44B14EFF)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.music_note_outlined,
                          color: _selectedGenre != null ? kAccent : kDim,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedGenre ?? 'Select a genre...',
                            style: TextStyle(
                              color: _selectedGenre != null ? Colors.white : kDim,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: _selectedGenre != null ? kAccent : kDim,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: nameReady ? 1.0 : 0.4,
                  child: PrimaryButton(
                    label: "Let's go →",
                    onPressed: _save,
                    loading: _submitting,
                    height: 56,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
    text,
    style: const TextStyle(color: kMuted, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.4),
  );

}
