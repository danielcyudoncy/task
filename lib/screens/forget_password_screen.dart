// views/forget_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:task/controllers/settings_controller.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final AuthController _auth = Get.find();

  ForgotPasswordScreen({super.key});

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _auth.forgotPassword(_emailController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark; // <-- Add this line

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? [Colors.grey[900]!, Colors.grey[800]!]
                  .reduce((value, element) => value)
              : Theme.of(context).colorScheme.primary,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: SingleChildScrollView(
              child: Column(children: [
                // Back arrow
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24.sp, // adjust the size as needed
                      ),
                      onPressed: () {
                        Get.find<SettingsController>().triggerFeedback();
                        Get.back();
                      },
                    )
                  ],
                ),
                // Logo
                Image.asset(
                  'assets/png/logo.png',
                  width: 213.w,
                  height: 216.h,
                ),

                // Forgot Password Card
                Container(
                  width: 350.w,
                  constraints: BoxConstraints(
                    minHeight: 300.h,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  padding: EdgeInsets.all(40.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Text(
                          "Forgot Password",
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'raleway',
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 15.h),

                        // Description
                        Text(
                          "Enter your email address to receive a password reset link.",
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 31.h),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          style: textTheme.bodyMedium,
                          decoration: InputDecoration(
                            labelText: "Email",
                            labelStyle: textTheme.bodyMedium,
                            hintStyle: textTheme.bodyMedium,
                            prefixIcon: Icon(Icons.email,
                                color: colorScheme.onSurfaceVariant),
                            filled: true,
                            fillColor: theme.brightness == Brightness.light
                                ? Colors.grey[200]
                                : Colors.grey[800],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter your email";
                            }
                            if (!GetUtils.isEmail(value)) {
                              return "Please enter a valid email";
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 30.h),

                        // Save Changes Button
                        Obx(() {
                          if (!Get.isRegistered<AuthController>()) {
                            return SizedBox(
                              width: double.infinity,
                              height: 48.h,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.secondary,
                                  foregroundColor: isDark
                                      ? Colors.black
                                      : colorScheme.onSecondary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                onPressed: () {
                                  Get.find<SettingsController>()
                                      .triggerFeedback();
                                  _submit();
                                },
                                child: Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.black
                                        : colorScheme.onSecondary,
                                  ),
                                ),
                              ),
                            );
                          }

                          return _auth.isLoading.value
                              ? const Center(child: CircularProgressIndicator())
                              : SizedBox(
                                  width: double.infinity,
                                  height: 48.h,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.secondary,
                                      foregroundColor: isDark
                                          ? Colors.black
                                          : colorScheme.onSecondary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                      ),
                                    ),
                                    onPressed: () {
                                      Get.find<SettingsController>()
                                          .triggerFeedback();
                                      _submit();
                                    },
                                    child: Text(
                                      'Save Changes',
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.black
                                            : colorScheme.onSecondary,
                                      ),
                                    ),
                                  ),
                                );
                        }),
                      ],
                    ),
                  ),
                ),
              ]),
              // Add some bottom spacing
            ),
          ),
        ),
      ),
    );
  }
}
