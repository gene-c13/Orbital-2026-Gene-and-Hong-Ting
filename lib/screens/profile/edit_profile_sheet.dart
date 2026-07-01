import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:after_hours/theme/app_theme.dart';
import 'package:after_hours/services/user_service.dart';

const _genres = [
  'House', 'Techno', 'Drum & Bass', 'Hip-Hop', 'R&B',
  'Afrobeats', 'Garage', 'Trance', 'Disco', 'Jungle',
  'Dubstep', 'Pop', 'Reggaeton', 'Latin', 'Other',
];

class EditProfileSheet extends StatefulWidget {
  final String  initialName;
  final String  username;
  final String  initialVenue;
  final String? initialGenre;
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
  });

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _venueController;

  String?    _selectedGenre;
  Uint8List? _pickedBytes;
  bool       _submitting = false;
  bool       _isPublic = true;

  @override
  void initState() {
    super.initState();
    _nameController  = TextEditingController(text: widget.initialName);
    _venueController = TextEditingController(text: widget.initialVenue);
    _selectedGenre   = widget.initialGenre;
    _isPublic = widget.initialIsPublic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF130228),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 16, 6),
              child: Text(
                'Update photo',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: kAccent),
              title: const Text('Take photo', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: kAccent),
              title: const Text('Choose from gallery', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(source: source, maxWidth: 800, imageQuality: 85);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _pickedBytes = bytes;
    });
  }

  void _showGenrePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF130228),
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
                      color:      selected ? kAccent : Colors.white,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: selected ? const Icon(Icons.check, color: kAccent, size: 18) : null,
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
            color: Color(0xFF130228),
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
                                  border: Border.all(color: const Color(0xFF130228), width: 2),
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
                      decoration: BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kBorder),
                      ),
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
                    _inputField(
                      controller:     _nameController,
                      hint:           'e.g. Alex',
                      icon:           Icons.person_outline,
                      capitalization: TextCapitalization.words,
                      action:         TextInputAction.next,
                      onChanged:      (_) => setState(() {}),
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
                      decoration: BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: kBorder),
                      ),
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
                    _inputField(
                      controller: _venueController,
                      hint:       'e.g. Fabric, Printworks...',
                      icon:       Icons.location_on_outlined,
                      action:     TextInputAction.done,
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: nameReady ? 1.0 : 0.4,
                        child: Container(
                          decoration: kPrimaryButtonDecoration,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor:     Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.4,
                              ),
                            ),
                            onPressed: (_submitting || !nameReady) ? null : _save,
                            child: _submitting
                                ? const SizedBox(
                                    width: 22, height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('SAVE CHANGES'),
                          ),
                        ),
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

  Widget _inputField({
    required TextEditingController controller,
    required String  hint,
    required IconData icon,
    TextCapitalization  capitalization = TextCapitalization.none,
    TextInputAction     action         = TextInputAction.next,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color:  kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x44B14EFF)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: kAccent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller:           controller,
              textCapitalization:   capitalization,
              textInputAction:      action,
              onChanged:            onChanged,
              onSubmitted:          onSubmitted,
              style:                const TextStyle(color: Colors.white, fontSize: 16),
              cursorColor:          kAccent,
              decoration: InputDecoration(
                hintText:       hint,
                hintStyle:      const TextStyle(color: kDim, fontSize: 16),
                border:         InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}