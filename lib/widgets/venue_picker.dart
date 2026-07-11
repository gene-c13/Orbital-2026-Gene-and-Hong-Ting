import 'package:flutter/material.dart';
import 'package:after_hours/theme/app_theme.dart';

void showVenuePicker(BuildContext context, String? selected, List<String> venues, void Function(String) onPicked) {
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
          'Choose a venue',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: venues.isEmpty 
                ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No venues found yet.' , style: TextStyle(color: kDim)),
                )
              : ListView(
                  shrinkWrap: true,
                  children: venues.map((venue) {
              final isSelected = venue == selected;
              return ListTile(
                title: Text(
                  venue,
                  style: TextStyle(
                    color: isSelected ? kAccent : Colors.white,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check, color: kAccent, size: 18) : null,
                onTap: () {
                  onPicked(venue);
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
