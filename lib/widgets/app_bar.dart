// widgets/app_bar.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/settings_controller.dart';

class AppBarWidget extends StatelessWidget {
  final double basePadding;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  
  const AppBarWidget({
    required this.basePadding, 
    this.scaffoldKey,
    super.key
  });

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: basePadding, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Get.find<SettingsController>().triggerFeedback();
              if (scaffoldKey?.currentState != null) {
                scaffoldKey!.currentState!.openDrawer();
              }
            },
            child: Semantics(
              label: "Open Menu",
              button: true,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Get.find<SettingsController>().triggerFeedback();
              Get.offAllNamed('/profile');
            },
            child: Semantics(
              label: "Go to profile",
              button: true,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
