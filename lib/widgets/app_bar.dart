// widgets/app_bar.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/auth_controller.dart';

class AppBarWidget extends StatelessWidget {
  final double basePadding;
  const AppBarWidget({required this.basePadding, super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final AuthController authController = Get.find<AuthController>();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: basePadding, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => authController.goToHome(),
            child: Semantics(
              label: "Go to Home",
              button: true,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border.all(
                      color:
                          isDarkMode ? Colors.white : const Color(0xFF171FA0)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.home,
                  color: isDarkMode ? Colors.white : const Color(0xFF171FA0),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Get.offAllNamed('/profile'),
            child: Semantics(
              label: "Go to profile",
              button: true,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border.all(
                      color:
                          isDarkMode ? Colors.white : const Color(0xFF171FA0)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_circle,
                  color: isDarkMode ? Colors.white : const Color(0xFF171FA0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
