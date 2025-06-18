// widgets/header_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../controllers/auth_controller.dart';

class HeaderWidget extends StatelessWidget {
  final AuthController authController;

  const HeaderWidget({super.key, required this.authController});

  @override
  Widget build(BuildContext context) {

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
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
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color:
                              const Color(0xFF08169D), // Set text color to blue
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text(
                      'Welcome',
                      style:
                          TextStyle(fontSize: 24.sp,
                          fontFamily: 'Raleway',
                          color: const ColorScheme.light().onPrimary,
                           fontWeight: FontWeight.bold),
                    ),
                    Text(
                      authController.fullName.value,
                      style: TextStyle(fontSize: 16.sp,
                      fontWeight:  FontWeight.w700,
                      color: const ColorScheme.light().onPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          border: Border.all(color: const Color(0xFF08169D), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.blue,
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF08169D), size: 20),
      ),
    );
  }
}
