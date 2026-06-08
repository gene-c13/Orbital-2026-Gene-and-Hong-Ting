import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color kSurface = Color(0x14FFFFFF);
const Color kBorder  = Color(0x22FFFFFF);
const Color kAccent  = Color(0xFFB14EFF);
const Color kMuted   = Color(0xCCFFFFFF);

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _captionController  = TextEditingController();
  final _venueController    = TextEditingController();
  final _eventController    = TextEditingController();

  double _rating   = 0;   // 0 = not set
  bool _submitting = false;

  @override
  void dispose() {
    _captionController.dispose();
    _venueController.dispose();
    _eventController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final caption = _captionController.text.trim();
    if (caption.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something about your night first.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final username = user.displayName ?? user.email?.split('@').first ?? 'Raver';

      await FirebaseFirestore.instance.collection('posts').add({
        'uid':           user.uid,
        'username':      username,
        'caption':       caption,
        'venue_tag':     _venueController.text.trim(),
        'event_tag':     _eventController.text.trim(),
        'rating':        _rating > 0 ? _rating : null,
        'image_url':     '',   // TODO: wire up Firebase Storage
        'likes':         [],
        'comment_count': 0,
        'created_at':    FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E1065), Color(0xFF5B21B6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Log your night',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    _submitting
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                          )
                        : TextButton(
                            onPressed: _submit,
                            child: const Text(
                              'Post',
                              style: TextStyle(color: kAccent, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Caption
                      _card(
                        child: TextField(
                          controller: _captionController,
                          maxLines: 5,
                          minLines: 3,
                          maxLength: 300,
                          style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                          decoration: const InputDecoration(
                            hintText: 'How was your night? Tell the crew...',
                            hintStyle: TextStyle(color: Color(0x66FFFFFF)),
                            border: InputBorder.none,
                            counterStyle: TextStyle(color: Color(0x66FFFFFF)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Rating
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Rate your night', style: TextStyle(color: kMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(5, (i) {
                                final star = i + 1.0;
                                final filled = star <= _rating;
                                return GestureDetector(
                                  onTap: () => setState(() => _rating = star),
                                  child: Icon(
                                    filled ? Icons.star : Icons.star_border,
                                    color: filled ? kAccent : const Color(0x55FFFFFF),
                                    size: 36,
                                  ),
                                );
                              }),
                            ),
                            if (_rating > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Center(
                                  child: Text(
                                    _ratingLabel(_rating),
                                    style: const TextStyle(color: kMuted, fontSize: 12),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Venue + event tags
                      _card(
                        child: Column(
                          children: [
                            _tagField(
                              controller: _venueController,
                              icon: Icons.location_on,
                              hint: 'Venue (e.g. Fabric)',
                              divider: true,
                            ),
                            _tagField(
                              controller: _eventController,
                              icon: Icons.confirmation_number,
                              hint: 'Event name (optional)',
                              divider: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Photo — placeholder until Firebase Storage is set up
                      GestureDetector(
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Photo upload coming soon!')),
                        ),
                        child: _card(
                          child: Row(
                            children: const [
                              Icon(Icons.add_photo_alternate_outlined, color: kAccent, size: 22),
                              SizedBox(width: 12),
                              Text('Add a photo', style: TextStyle(color: kMuted, fontSize: 14)),
                              Spacer(),
                              Icon(Icons.chevron_right, color: Color(0x55FFFFFF), size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Post button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          child: const Text('Post to feed'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: child,
    );
  }

  Widget _tagField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required bool divider,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: kAccent, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: Color(0x66FFFFFF)),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
        if (divider)
          Divider(height: 20, color: kBorder),
      ],
    );
  }

  String _ratingLabel(double rating) {
    switch (rating.toInt()) {
      case 1: return 'Awful night';
      case 2: return 'Not great';
      case 3: return 'Decent';
      case 4: return 'Great night';
      case 5: return 'All-timer 🔥';
      default: return '';
    }
  }
}