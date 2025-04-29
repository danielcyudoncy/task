// views/profile_update_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/widgets/save_success_screen.dart';
import '../controllers/auth_controller.dart';
import 'package:task/utils/constants/app_icons.dart';
import 'package:task/utils/constants/app_colors.dart';
import '../widgets/image_picker_widget.dart';
 // Import your UserScreen

class ProfileUpdateScreen extends StatelessWidget {
  ProfileUpdateScreen({super.key});

  final AuthController auth = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFF2e3bb5)],
          ),
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
                    color: AppColors.primaryColor,
                    onPressed: () => Get.back(),
                  ),
                ),

                const SizedBox(height: 8),
                // App logo
                Image.asset(
                  AppIcons.logo,
                  width: 80,
                  height: 80,
                ),
                const SizedBox(height: 24),

                // Form card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
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
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Adjust the content below to update your profile.',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Profile picture picker
                        ImagePickerWidget(controller: auth),
                        const SizedBox(height: 24),

                        // Full Name
                        TextFormField(
                          controller: auth.fullNameController,
                          decoration: InputDecoration(
                            hintText: 'Full Name',
                            filled: true,
                            fillColor: Colors.grey[200],
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
                          decoration: InputDecoration(
                            hintText: 'Phone Number',
                            filled: true,
                            fillColor: Colors.grey[200],
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
                          decoration: InputDecoration(
                            hintText: 'Email Address',
                            filled: true,
                            fillColor: Colors.grey[200],
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
                                      child: Text(role),
                                    ))
                                .toList(),
                            onChanged: (v) => auth.selectedRole.value = v!,
                            decoration: InputDecoration(
                              hintText: 'Role',
                              filled: true,
                              fillColor: Colors.grey[200],
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
                                      if (_formKey.currentState!.validate()) {
                                        await auth.updateProfileDetails();

                                        // Navigate to SaveSuccessScreen after profile update
                                        Get.offAll(() => const SaveSuccessScreen(),
                                            predicate: (route) => false);
                                      }
                                    },
                                    child: const Text(
                                      'Save Changes',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
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
