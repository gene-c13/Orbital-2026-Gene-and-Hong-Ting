import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/services/user_service.dart';
import 'package:after_hours/widgets/app_text_field.dart';
import 'package:after_hours/widgets/genre_picker.dart';
import 'package:after_hours/widgets/image_source_sheet.dart';
import 'package:after_hours/widgets/primary_button.dart';

class EditProfileSheet extends StatefulWidget {
  final String  initialName;
  final String  username;
  final String  initialVenue;
  final String? initialGenre;
  final String  initialBio;
  final bool initialIsPublic;
  final String? initialPhotoUrl;
  final String  uid;
  final VoidCallback onSaved;

  const EditProfileSheet({
    super.key,
    required this.initialName,
    required this.username,
    required this.initialVenue,
    required this.initialGenre,
    required this.initialIsPublic,
    required this.initialPhotoUrl,
    required this.uid,
    required this.onSaved,
    required this.initialBio,
  });

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _venueController;
  late final TextEditingController _bioController;

  String?    _selectedGenre;
  Uint8List? _pickedBytes;
  bool       _submitting = false;
  bool       _isPublic = true;

  @override
  void initState() {
    super.initState();
    _nameController  = TextEditingController(text: widget.initialName);
    _venueController = TextEditingController(text: widget.initialVenue);
    _bioController = TextEditingController(text: widget.initialBio);
    _selectedGenre   = widget.initialGenre;
    _isPublic = widget.initialIsPublic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _pickAvatar() async {
    final source = await showImageSourceSheet(context, 'Update photo');
    if (source == null || !mounted) return;

    final picked = await ImagePicker().pickImage(source: source, maxWidth: 800, imageQuality: 85);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _pickedBytes = bytes;
    });
  }

  void _showGenrePicker() {
    showGenrePicker(context, _selectedGenre, (genre) {
      setState(() => _selectedGenre = genre);
    });
  }

Future<void> _save() async {
  final name = _nameController.text.trim();
  if (name.length < 2) {
    _snack('Name must be at least 2 characters.');
    return;
  }

  setState(() => _submitting = true);

  try {
    await UserService().updateProfile(
      uid:            widget.uid,
      displayName:    name,
      favouriteVenue: _venueController.text.trim(),
      favouriteGenre: _selectedGenre ?? '',
      isPublic:       _isPublic,
      avatarBytes:    _pickedBytes,
      bio:            _bioController.text.trim(),
    );

    if (!mounted) return;
    widget.onSaved();
    Navigator.of(context).pop();
  } catch (e) {
    if (!mounted) return;
    _snack('Failed to save: $e');
  } finally {
    if (mounted) setState(() => _submitting = false);
  }
}
  

  @override
  Widget build(BuildContext context) {
    final nameReady = _nameController.text.trim().length >= 2;

    ImageProvider? previewImage;
    if (_pickedBytes != null) {
      previewImage = MemoryImage(_pickedBytes!);
    } else if (widget.initialPhotoUrl != null) {
      previewImage = CachedNetworkImageProvider(widget.initialPhotoUrl!);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: kSheet,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0x44FFFFFF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                child: Row(
                  children: [
                    Text('Edit Profile', style: kNectarine(size: 22, letterSpacing: 1.5)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: kDim, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: kBorder),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
                  children: [

                    Center(
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: kAccent.withValues(alpha: 0.25),
                              backgroundImage: previewImage,
                              child: previewImage == null
                                  ? Text(
                                      _nameController.text.isNotEmpty
                                          ? _nameController.text[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: kAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: kSheet, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        'Tap to change photo',
                        style: TextStyle(color: kDim, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 32),

                    _fieldLabel('USERNAME'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
                      decoration: kCardDecoration,
                      child: Row(
                        children: [
                          const Icon(Icons.alternate_email, color: kDim, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('@${widget.username}',
                                style: const TextStyle(color: kDim, fontSize: 16)),
                          ),
                          const Icon(Icons.lock_outline, color: kDim, size: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text("Username can't be changed",
                        style: TextStyle(color: kDim, fontSize: 11)),
                    const SizedBox(height: 22),
                    _fieldLabel('DISPLAY NAME *'),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller:     _nameController,
                      hint:           'e.g. Alex',
                      icon:           Icons.person_outline,
                      capitalization: TextCapitalization.words,
                      action:         TextInputAction.next,
                      onChanged:      (_) => setState(() {}),
                    ),
                    const SizedBox(height: 22),

                    _fieldLabel('BIO'),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _bioController,
                      hint:       'e.g. Party Animal',
                      icon:       Icons.notes_outlined,
                    ),
                    const SizedBox(height: 22),

                    _fieldLabel('FAVOURITE GENRE'),
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
                    const SizedBox(height: 22),
                    _fieldLabel('ACCOUNT PRIVACY'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: kCardDecoration,
                      child: Row(
                        children: [
                          Icon(
                            _isPublic ? Icons.public : Icons.lock_outline,
                            color: _isPublic ? kAccent : kDim,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isPublic ? 'Public account' : 'Private account',
                                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isPublic
                                      ? 'Your posts are visible to everyone'
                                      : 'Your posts are only visible to friends',
                                  style: const TextStyle(color: kDim, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isPublic,
                            onChanged: (val) => setState(() => _isPublic = val),
                            activeThumbColor: kAccent,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    _fieldLabel('FAVOURITE VENUE'),
                    const SizedBox(height: 8),
                    AppTextField(
                      controller: _venueController,
                      hint:       'e.g. Zouk...',
                      icon:       Icons.location_on_outlined,
                      action:     TextInputAction.done,
                    ),
                    const SizedBox(height: 40),

                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: nameReady ? 1.0 : 0.4,
                      child: PrimaryButton(
                        label: 'SAVE CHANGES',
                        onPressed: (_submitting || !nameReady) ? null : _save,
                        loading: _submitting,
                        height: 56,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _fieldLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: kDim, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5,
    ),
  );

}