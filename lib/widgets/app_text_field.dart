import 'package:flutter/material.dart';
import 'package:after_hours/theme/app_theme.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextCapitalization capitalization;
  final TextInputAction action;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.capitalization = TextCapitalization.none,
    this.action = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
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
              controller: controller,
              textCapitalization: capitalization,
              textInputAction: action,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              cursorColor: kAccent,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: kDim, fontSize: 16),
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
