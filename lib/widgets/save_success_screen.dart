// widgets/save_success_screen.dart
// views/save_success_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/settings_controller.dart';
import '../controllers/auth_controller.dart';
import 'package:task/utils/constants/app_icons.dart';
import 'package:task/utils/constants/app_colors.dart';

class SaveSuccessScreen extends StatefulWidget {
  const SaveSuccessScreen({super.key});

  @override
  State<SaveSuccessScreen> createState() => _SaveSuccessScreenState();
}

class _SaveSuccessScreenState extends State<SaveSuccessScreen> {
  @override
  void initState() {
    super.initState();
    // After 2 seconds, navigate based on role
    Timer(const Duration(seconds: 2), () {
      Get.find<AuthController>().navigateBasedOnRole();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFF2e3bb5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Back arrow if needed
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: AppColors.primaryColor,
                  onPressed: () {
                    Get.find<SettingsController>().triggerFeedback();
                    Get.back();
                  },
                ),
              ),
              const SizedBox(height: 16),
              // App logo
              Image.asset(
                AppIcons.logo,
                width: 80,
                height: 80,
              ),
              const SizedBox(height: 24),
              // Success card
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 100,
                          color: AppColors.primaryColor,
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Changes Saved\nsuccessfully',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2e3bb5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
