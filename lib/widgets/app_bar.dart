// widgets/app_bar.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppBarWidget extends StatelessWidget {
  final double basePadding;
  const AppBarWidget({required this.basePadding, super.key});

  @override
  Widget build(BuildContext context) {
    // Check the current theme mode (light or dark)
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: basePadding, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Get.back(),
            child: Semantics(
              label: "Back",
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
                  Icons.arrow_back,
                  color: isDarkMode
                      ? Colors.white
                      : const Color(
                          0xFF171FA0), // Change icon color based on theme
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
                  color: isDarkMode
                      ? Colors.white
                      : const Color(
                          0xFF171FA0), // Change icon color based on theme
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
