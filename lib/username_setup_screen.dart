import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'events_screen.dart';

const Color _kAccent = Color(0xFFB14EFF);
const Color _kMuted  = Color(0xCCFFFFFF);
const Color _kSurface = Color(0x14FFFFFF);
const Color _kBorder  = Color(0x44B14EFF);

// Common genre options for the picker
const _genres = [
  'House', 'Techno', 'Drum & Bass', 'Hip-Hop', 'R&B',
  'Afrobeats', 'Garage', 'Trance', 'Disco', 'Jungle',
  'Dubstep', 'Pop', 'Reggaeton', 'Latin', 'Other',
];

class UsernameSetupScreen extends StatefulWidget {
  const UsernameSetupScreen({super.key});

  @override
  State<UsernameSetupScreen> createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends State<UsernameSetupScreen> {
  final _nameController  = TextEditingController();
  final _venueController = TextEditingController();

  String? _selectedGenre;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name  = _nameController.text.trim();
    final venue = _venueController.text.trim();

    if (name.isEmpty) {
      _snack('Please enter your name.');
      return;
    }
    if (name.length < 2) {
      _snack('Name must be at least 2 characters.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      await user.updateDisplayName(name);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
            'display_name':     name,
            'favourite_venue':  venue,
            'favourite_genre':  _selectedGenre ?? '',
          }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EventsScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      _snack('Failed to save: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _showGenrePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A0A3B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0x44FFFFFF),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Favourite genre',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: _genres.map((genre) {
                final selected = genre == _selectedGenre;
                return ListTile(
                  title: Text(
                    genre,
                    style: TextStyle(
                      color: selected ? _kAccent : Colors.white,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: selected
                      ? const Icon(Icons.check, color: _kAccent, size: 18)
                      : null,
                  onTap: () {
                    setState(() => _selectedGenre = genre);
                    Navigator.of(ctx).pop();
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nameReady = _nameController.text.trim().length >= 2;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0420), Color(0xFF2B0B3A), Color(0xFF1A0533)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
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
                  style: TextStyle(color: _kMuted, fontSize: 15),
                ),
                const SizedBox(height: 36),

                // Name
                _fieldLabel('Your name *'),
                const SizedBox(height: 8),
                _inputField(
                  controller: _nameController,
                  hint: 'e.g. Alex',
                  icon: Icons.person_outline,
                  capitalization: TextCapitalization.words,
                  action: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),

                // Favourite venue
                _fieldLabel('Favourite venue'),
                const SizedBox(height: 8),
                _inputField(
                  controller: _venueController,
                  hint: 'e.g. Fabric, Printworks...',
                  icon: Icons.location_on_outlined,
                  action: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                ),
                const SizedBox(height: 20),

                // Favourite genre — tap to open picker
                _fieldLabel('Favourite music genre'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showGenrePicker,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
                    decoration: BoxDecoration(
                      color: _kSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _kBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.music_note_outlined,
                          color: _selectedGenre != null ? _kAccent : const Color(0x55FFFFFF),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedGenre ?? 'Select a genre...',
                            style: TextStyle(
                              color: _selectedGenre != null ? Colors.white : const Color(0x55FFFFFF),
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: _selectedGenre != null ? _kAccent : const Color(0x55FFFFFF),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Continue button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: nameReady ? 1.0 : 0.45,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB14EFF), Color(0xFFFF2D95)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: nameReady
                            ? const [BoxShadow(color: Color(0x66FF2D95), blurRadius: 24, spreadRadius: 1)]
                            : [],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _submitting ? null : _save,
                        child: _submitting
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                "Let's go →",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Widget helpers ────────────────────────────────────────────────────

  Widget _fieldLabel(String text) => Text(
    text,
    style: const TextStyle(color: _kMuted, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.4),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextCapitalization capitalization = TextCapitalization.none,
    TextInputAction action = TextInputAction.next,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: _kAccent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: capitalization,
              textInputAction: action,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              cursorColor: _kAccent,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0x55FFFFFF), fontSize: 16),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
