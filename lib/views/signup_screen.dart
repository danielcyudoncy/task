// views/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/utils/devices/app_devices.dart';
import '../controllers/auth_controller.dart';
import '../utils/constants/app_icons.dart';

class SignUpScreen extends StatelessWidget {
  final AuthController authController = Get.put(AuthController());
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).canvasColor
          : Theme.of(context).colorScheme.primary,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).canvasColor
              : Theme.of(context).colorScheme.primary,
        ),

        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                      top: 5, left: 20, right: 15, bottom: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20.r),
                          child: Image.asset(
                            AppIcons.logo,
                            height: 100.h,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24.w),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: theme.brightness == Brightness.light
                              ? [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10.r,
                                    offset: Offset(0, 4.h),
                                  ),
                                ]
                              : null,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Text(
                                'create_account'.tr,
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'raleway',
                                  fontSize: 22.sp,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'adjust_content_below'.tr,
                                style: textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 24.h),

                              // Full Name
                              _buildTextField(
                                context: context,
                                controller: fullNameController,
                                icon: Icons.person,
                                hint: 'full_name'.tr,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'full_name_cannot_be_empty'.tr;
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 12.h),

                              // Email
                              _buildTextField(
                                context: context,
                                controller: emailController,
                                icon: Icons.email,
                                hint: 'email'.tr,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'email_cannot_be_empty'.tr;
                                  }
                                  if (!GetUtils.isEmail(value)) {
                                    return 'enter_valid_email'.tr;
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 12.h),

                              // Password with visibility toggle
                              Obx(() => _buildTextField(
                                    context: context,
                                    controller: passwordController,
                                    obscureText: authController
                                        .isSignUpPasswordHidden.value,
                                    icon: Icons.lock,
                                    hint: 'password'.tr,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'password_cannot_be_empty'.tr;
                                      }
                                      if (value.length < 6) {
                                        return 'password_min_length'.tr;
                                      }
                                      return null;
                                    },
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        authController
                                                .isSignUpPasswordHidden.value
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        Get.find<SettingsController>()
                                            .triggerFeedback();
                                        authController.isSignUpPasswordHidden
                                            .toggle();
                                      },
                                    ),
                                  )),
                              SizedBox(height: 12.h),

                              // Confirm Password with visibility toggle
                              Obx(() => _buildTextField(
                                    context: context,
                                    controller: confirmPasswordController,
                                    obscureText: authController
                                        .isConfirmPasswordHidden.value,
                                    icon: Icons.lock,
                                    hint: 'confirm_password'.tr,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'please_confirm_password'.tr;
                                      }
                                      if (value != passwordController.text) {
                                        return 'passwords_do_not_match'.tr;
                                      }
                                      return null;
                                    },
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        authController
                                                .isConfirmPasswordHidden.value
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                      onPressed: () {
                                        Get.find<SettingsController>()
                                            .triggerFeedback();
                                        authController.isConfirmPasswordHidden
                                            .toggle();
                                      },
                                    ),
                                  )),
                              SizedBox(height: 12.h),

                              // Role Dropdown
                              Obx(() => DropdownButtonFormField<String>(
                                    value: authController
                                            .selectedRole.value.isEmpty
                                        ? null
                                        : authController.selectedRole.value,
                                    icon: const Icon(Icons.arrow_drop_down),
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      hintText: 'select_role'.tr,
                                      prefixIcon:
                                          const Icon(Icons.person_outline),
                                      filled: true,
                                      fillColor:
                                          theme.brightness == Brightness.light
                                              ? Colors.grey[200]
                                              : Colors.grey[800],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    dropdownColor: colorScheme.surface,
                                    style: textTheme.bodyMedium,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'please_select_role'.tr;
                                      }
                                      return null;
                                    },
                                    onChanged: (String? value) {
                                      authController.selectedRole.value =
                                          value!;
                                    },
                                    items: authController.userRoles.map((role) {
                                      return DropdownMenuItem(
                                        value: role,
                                        child: Text(role),
                                      );
                                    }).toList(),
                                  )),
                              SizedBox(height: 20.h),

                              // Sign Up Button
                              Obx(() {
                                // Add safety check to ensure controller is registered
                                if (!Get.isRegistered<AuthController>()) {
                                  return SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      // Using theme's default button styling
                                      onPressed: () => _signUp(context),
                                      child: Text(
                                        'save_continue'.tr,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'raleway',
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return authController.isLoading.value
                                    ? const CircularProgressIndicator()
                                    : SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          // Using theme's default button styling
                                          onPressed: () => _signUp(context),
                                          child: Text(
                                            'save_continue'.tr,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'raleway',
                                            ),
                                          ),
                                        ),
                                      );
                              }),

                              SizedBox(height: 20.h),

                              Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text('or_sign_up_with'.tr,
                                        style: textTheme.bodyMedium),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                              SizedBox(height: 16.h),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Image.asset(AppIcons.google,
                                        width: 48.w, height: 48.h),
                                    onPressed: () {
                                      Get.find<SettingsController>()
                                          .triggerFeedback();
                                      Get.snackbar('coming_soon'.tr,
                                          'google_signup_not_implemented'.tr,
                                          backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        colorText: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      );
                                    },
                                  ),
                                  SizedBox(width: 20.w),
                                  IconButton(
                                    icon: Image.asset(AppIcons.apple,
                                        width: 48.w, height: 48.h),
                                    onPressed: () {
                                      Get.find<SettingsController>()
                                          .triggerFeedback();
                                      Get.snackbar('coming_soon'.tr,
                                          'apple_signup_not_implemented'.tr,
                                          backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .surface,
                                        colorText: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      );
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('already_have_account'.tr,
                                      style: textTheme.bodyMedium),
                                  GestureDetector(
                                    onTap: () {Get.find<SettingsController>().triggerFeedback(); Get.toNamed('/login');},
                                    child: Text(
                                      'sign_in'.tr,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.secondary,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'raleway',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 40.h),
                    ],
                  ),
                ),
              ),

              // Back Arrow
              Positioned(
                top: 10.h,
                left: 20.w,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: colorScheme.primary),
                  onPressed: () {Get.find<SettingsController>().triggerFeedback(); Get.back();},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    required String? Function(String?) validator,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: theme.brightness == Brightness.light
            ? Colors.grey[200]
            : Colors.grey[800],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _signUp(BuildContext context) {
    AppDevices.hideKeyboard(context);
    if (_formKey.currentState!.validate()) {
      authController.signUp(
        fullNameController.text.trim(),
        emailController.text.trim(),
        passwordController.text.trim(),
        authController.selectedRole.value,
      );
    }
  }
}
