import 'package:flutter/material.dart';
import 'package:after_hours/theme/app_theme.dart';

//bottom sheet listing the genres with a tick on the current one. kept here
//so profile setup and edit profile share it instead of both building one
void showGenrePicker(BuildContext context, String? selected, void Function(String) onPicked) {
  showModalBottomSheet(
    context: context,
    backgroundColor: kSheet,
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
            children: kGenres.map((genre) {
              final isSelected = genre == selected;
              return ListTile(
                title: Text(
                  genre,
                  style: TextStyle(
                    color: isSelected ? kAccent : Colors.white,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check, color: kAccent, size: 18) : null,
                onTap: () {
                  onPicked(genre);
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
