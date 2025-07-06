// views/profile_update_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/widgets/save_success_screen.dart';
import '../controllers/auth_controller.dart';
import 'package:task/utils/constants/app_icons.dart';
import 'package:task/utils/constants/app_colors.dart';
import '../widgets/image_picker_widget.dart';
import '../utils/snackbar_utils.dart';

class ProfileUpdateScreen extends StatelessWidget {
  ProfileUpdateScreen({super.key});

  final AuthController auth = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Prefill form controllers
    auth.fullNameController.text = auth.fullName.value;
    auth.emailController.text = auth.auth.currentUser?.email ?? '';
    auth.phoneNumberController.text = auth.phoneNumberController.text;
    auth.selectedRole.value = auth.userRole.value;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? Colors.black : AppColors.primaryColor,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: isDark ? Colors.white : Colors.white,
                    onPressed: () {Get.find<SettingsController>().triggerFeedback(); Get.back();},
                  ),
                ),
                const SizedBox(height: 8),

                // App logo
                Image.asset(
                  AppIcons.logo,
                  width: 80.w,
                  height: 80.h,
                ),
                const SizedBox(height: 24),

                // Form Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isDark
                        ? []
                        : const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Update Account',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'raleway',
                                color: isDark ? Colors.white : Colors.black,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        Text(
                          'Adjust the content below to update your profile.',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontFamily: 'raleway',
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        ImagePickerWidget(controller: auth),
                        const SizedBox(height: 24),

                        // Full Name
                        TextFormField(
                          controller: auth.fullNameController,
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Full Name',
                            hintStyle: TextStyle(
                                color:
                                    isDark ? Colors.white54 : Colors.black54),
                            filled: true,
                            fillColor:
                                isDark ? Colors.grey[850] : Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Please enter your name'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Phone Number
                        TextFormField(
                          controller: auth.phoneNumberController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Phone Number',
                            hintStyle: TextStyle(
                                color:
                                    isDark ? Colors.white54 : Colors.black54),
                            filled: true,
                            fillColor:
                                isDark ? Colors.grey[850] : Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Please enter phone number'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Email Address
                        TextFormField(
                          controller: auth.emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Email Address',
                            hintStyle: TextStyle(
                                color:
                                    isDark ? Colors.white54 : Colors.black54),
                            filled: true,
                            fillColor:
                                isDark ? Colors.grey[850] : Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) => v == null || !GetUtils.isEmail(v)
                              ? 'Please enter a valid email'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Role Dropdown
                        Obx(
                          () => DropdownButtonFormField<String>(
                            value: auth.selectedRole.value.isEmpty
                                ? null
                                : auth.selectedRole.value,
                            items: auth.userRoles
                                .map((role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(
                                        role,
                                        style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) => auth.selectedRole.value = v!,
                            dropdownColor:
                                isDark ? Colors.grey[850] : Colors.white,
                            style: TextStyle(
                                color: isDark ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Role',
                              hintStyle: TextStyle(
                                  color:
                                      isDark ? Colors.white54 : Colors.black54),
                              filled: true,
                              fillColor:
                                  isDark ? Colors.grey[850] : Colors.grey[200],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Please select a role'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Save Changes button
                        Obx(
                          () => auth.isLoading.value
                              ? const CircularProgressIndicator()
                              : SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () async {
                                      Get.find<SettingsController>()
                                          .triggerFeedback();
                                      if (_formKey.currentState!.validate()) {
                                        await auth.completeProfile();
                                        // Navigate to success screen first, then to appropriate dashboard
                                        Get.offAll(
                                            () => const SaveSuccessScreen(),
                                            predicate: (route) => false);
                                      }
                                    },
                                    child:  Text(
                                      'Save Changes',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
