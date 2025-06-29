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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.surface,
                    Colors.grey.shade900,
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF08169D),
                    Color(0xFF08169D),
                  ],
                ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Back arrow
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24, // adjust the size as needed
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
                  width: 113.w,
                  height: 116.h,
                ),
                const SizedBox(height: 56),

                // Forgot Password Card
                SizedBox(
                  width: 350.w,
                  height: 400.h,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Title
                          Text(
                            "Forgot Password",
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'raleway',
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Description
                          Text(
                            "Enter your email address to receive a password reset link.",
                            style: textTheme.bodyLarge?.copyWith(
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 31),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            style: textTheme.bodyMedium,
                            decoration: InputDecoration(
                              labelText: "Email",
                              labelStyle: textTheme.bodyMedium,
                              hintStyle: textTheme.bodyMedium,
                              prefixIcon: Icon(Icons.email,
                                  color:
                                      isDark ? Colors.white70 : Colors.black54),
                              filled: true,
                              fillColor:
                                  isDark ? Colors.grey[700] : Colors.grey[200],
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

                          const SizedBox(height: 30),

                          // Save Changes Button
                          Obx(() => _auth.isLoading.value
                              ? const Center(child: CircularProgressIndicator())
                              : SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      Get.find<SettingsController>().triggerFeedback();
                                      _submit();
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
                                )),
                        ],
                      ),
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
