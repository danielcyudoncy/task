// widgets/header_widget.dart
import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';

class HeaderWidget extends StatelessWidget {
  final AuthController authController;

  const HeaderWidget({super.key, required this.authController});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: authController.profilePic.value.isNotEmpty
                  ? NetworkImage(authController.profilePic.value)
                  : null,
              child: authController.profilePic.value.isEmpty
                  ? Text(
                      authController.fullName.value.isNotEmpty
                          ? authController.fullName.value[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            const Text(
              'Welcome',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Text(
              authController.fullName.value,
              style: const TextStyle(fontSize: 24),
            ),
          ],
        ),
        Row(
          children: [
            _iconButton(Icons.camera_alt, () {}),
            const SizedBox(width: 10),
            _iconButton(Icons.logout, authController.logout),
          ],
        ),
      ],
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: const Color(0xFF0B189B), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF0B189B), size: 20),
      ),
    );
  }
}
