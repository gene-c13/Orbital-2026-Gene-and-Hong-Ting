import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:after_hours/theme/app_theme.dart';

//bottom sheet asking camera or gallery, shared by edit profile and create
//post. gives back the choice, or null if they tapped away
Future<ImageSource?> showImageSourceSheet(BuildContext context, String title) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: kSheet,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 6),
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
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
}
