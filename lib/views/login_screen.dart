// views/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:task/utils/constants/app_icons.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthController _auth = Get.find();

  LoginScreen({super.key});

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _auth.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // App Logo
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              AppIcons.logo,
                              height: 200,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Main box container
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              if (!isDark)
                                const BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  "Welcome Back",
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24.sp,
                                    fontFamily: 'Raleway',
                                    color: textTheme.headlineMedium?.color,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Fill out the information below in order to access your account.",
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontSize: 14.sp,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),

                                // Email Field
                                TextFormField(
                                  controller: _emailController,
                                  style: textTheme.bodyMedium,
                                  decoration: InputDecoration(
                                    labelText: "Email",
                                    labelStyle: textTheme.bodyMedium,
                                    hintStyle: textTheme.bodyMedium,
                                    prefixIcon: Icon(Icons.email,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54),
                                    filled: true,
                                    fillColor: isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
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

                                const SizedBox(height: 16),

                                // Password Field
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  style: textTheme.bodyMedium,
                                  decoration: InputDecoration(
                                    labelText: "Password",
                                    labelStyle: textTheme.bodyMedium,
                                    hintStyle: textTheme.bodyMedium,
                                    prefixIcon: Icon(Icons.lock,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54),
                                    filled: true,
                                    fillColor: isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Please enter your password";
                                    }
                                    if (value.length < 6) {
                                      return "Password must be at least 6 characters";
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 24),

                                // Sign In Button
                                Obx(() => _auth.isLoading.value
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor:
                                              colorScheme.onPrimary,
                                          backgroundColor: colorScheme.primary,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: _submit,
                                        child: Text(
                                          "Sign In",
                                          style: textTheme.bodyLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Raleway',
                                              color: colorScheme.onPrimary),
                                        ),
                                      )),

                                const SizedBox(height: 24),

                                // Divider with text
                                Row(
                                  children: [
                                    const Expanded(child: Divider()),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Text(
                                        "or continue with",
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      ),
                                    ),
                                    const Expanded(child: Divider()),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Animated Google & Apple Login Buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Image.asset(AppIcons.google,
                                          width: 48.w, height: 48.h),
                                      onPressed: () {
                                        Get.snackbar("Coming Soon",
                                            "Google sign-up not yet implemented.");
                                      },
                                    ),
                                    const SizedBox(width: 20),
                                    IconButton(
                                      icon: Image.asset(AppIcons.apple,
                                          width: 48, height: 48),
                                      onPressed: () {
                                        Get.snackbar("Coming Soon",
                                            "Apple sign-up not yet implemented.");
                                      },
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 24),

                                // Bottom text
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => Get.toNamed('/signup'),
                                      child: Text(
                                        "Create Account",
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                GestureDetector(
                                  onTap: () {
                                    Get.toNamed('/forgot-password');
                                    },
                                  child: Text(
                                    "Forget password?",
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium?.copyWith(
                                      decoration: TextDecoration.underline,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Raleway',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: IconButton(
              icon: Icon(Icons.arrow_back,
                  color: isDark ? Colors.white : colorScheme.primary),
              onPressed: () {
                Get.back();
              },
            ),
          ),
        ],
      ),
    );
  }
}
