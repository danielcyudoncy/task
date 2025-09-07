// widgets/role_dropdown_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

Widget buildRoleDropdown(AuthController controller) {
  const List<String> roles = ['Admin', 'Assignment Head', 'HODs', 'DOPs', 'Driver', 'Librarian'];

  final inputDecoration = InputDecoration(
    labelText: 'Role',
    prefixIcon: const Icon(Icons.account_circle),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );

  return Container(
    decoration: BoxDecoration(
      color: const Color.fromRGBO(169, 169, 169, 0.3),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Obx(() => DropdownButtonFormField<String>(
          initialValue: controller.userRole.value.isEmpty ? null : controller.userRole.value,
          onChanged: (newValue) {
            controller.userRole.value = newValue!;
          },
          items: roles.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          decoration: inputDecoration,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a role';
            }
            return null;
          },
        )),
  );
}