import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../utils/constants/app_colors.dart';

Widget buildSaveButton(AuthController controller, String userFullName,
    String email, String password) {
  return Obx(() => ElevatedButton(
        onPressed: controller.isLoading.value ||
                controller.userRole.value.isEmpty
            ? null
            : () {
                controller.signUp(
                    userFullName, email, password, controller.userRole.value);
              },
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppColors.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: controller.isLoading.value
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Save & Continue'),
      ));
}
