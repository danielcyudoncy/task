import 'package:flutter/material.dart';

Widget buildTextField({
  required String labelText,
  required String hintText,
  required ValueChanged<String> onChanged,
  IconData? icon,
}) {
  return Container(
    decoration: BoxDecoration(
      color: const Color.fromRGBO(169, 169, 169, 0.3),
      borderRadius: BorderRadius.circular(12),
    ),
    child: TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    ),
  );
}
