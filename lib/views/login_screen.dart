// views/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/utils/constants/app_icons.dart';
import '../controllers/auth_controller.dart';
import '../utils/snackbar_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthController _auth = Get.find();

  // Safe snackbar method
  void _safeSnackbar(String title, String message) {
    SnackbarUtils.showSnackbar(title, message);
  }

  @override
  void initState() {
    super.initState();
    debugPrint("LoginScreen: initState called");
    // Reset loading state to ensure we're not stuck in loading
    _auth.resetLoadingState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    debugPrint("LoginScreen: _submit called");
    if (_formKey.currentState!.validate()) {
      debugPrint("LoginScreen: Form validation passed, calling signIn");
      _auth.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } else {
      debugPrint("LoginScreen: Form validation failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("LoginScreen: build called, isLoading: ${_auth.isLoading.value}");
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
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).canvasColor
                  : Theme.of(context).colorScheme.primary,
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

                        const SizedBox(height: 2),

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
                                const SizedBox(height: 4),
                                Text(
                                  "Fill out the information below in order to access your account.",
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontSize: 14.sp,
                                    color: colorScheme.onSurface,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),

                                // Email Field
                                TextFormField(
                                  controller: _emailController,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: "Email",
                                    labelStyle: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    hintStyle: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    prefixIcon: Icon(Icons.email,
                                        color: colorScheme.onSurfaceVariant),
                                    filled: true,
                                    fillColor: Theme.of(context).brightness == Brightness.light
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

                                const SizedBox(height: 16),

                                // Password Field
                                Obx(() {
                                  if (!Get.isRegistered<AuthController>()) {
                                    return TextFormField(
                                      controller: _passwordController,
                                      obscureText: true,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurface,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: "Password",
                                        labelStyle: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        hintStyle: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        prefixIcon: Icon(Icons.lock,
                                            color: colorScheme.onSurfaceVariant),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            Icons.visibility_off,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          onPressed: () {},
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(context).brightness == Brightness.light
                                            ? Colors.grey[200]
                                            : Colors.grey[800],
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
                                    );
                                  }
                                  
                                  return TextFormField(
                                    controller: _passwordController,
                                    obscureText: _auth.isLoginPasswordHidden.value,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: "Password",
                                      labelStyle: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      hintStyle: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      prefixIcon: Icon(Icons.lock,
                                          color: colorScheme.onSurfaceVariant),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _auth.isLoginPasswordHidden.value
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        onPressed: () {
                                          Get.find<SettingsController>().triggerFeedback();
                                          _auth.isLoginPasswordHidden.value =
                                              !_auth.isLoginPasswordHidden.value;
                                        },
                                      ),
                                      filled: true,
                                      fillColor: Theme.of(context).brightness == Brightness.light
                                          ? Colors.grey[200]
                                          : Colors.grey[800],
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
                                  );
                                }),

                                const SizedBox(height: 20),

                                // Sign In Button
                                Obx(() {
                                  if (!Get.isRegistered<AuthController>()) {
                                    return ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: colorScheme.onPrimary,
                                        backgroundColor: colorScheme.primary,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () {
                                        Get.find<SettingsController>().triggerFeedback();
                                        _submit();
                                      },
                                      child: Text(
                                        "Sign In",
                                        style: textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Raleway',
                                            color: colorScheme.onPrimary),
                                      ),
                                    );
                                  }
                                  
                                  return _auth.isLoading.value
                                      ? const Center(child: CircularProgressIndicator())
                                      : ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: colorScheme.onPrimary,
                                            backgroundColor: colorScheme.primary,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: () {
                                            Get.find<SettingsController>().triggerFeedback();
                                            _submit();
                                          },
                                          child: Text(
                                            "Sign In",
                                            style: textTheme.bodyLarge?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Raleway',
                                                color: colorScheme.onPrimary),
                                          ),
                                        );
                                }),

                                const SizedBox(height: 20),

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
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    const Expanded(child: Divider()),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // Animated Google & Apple Login Buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Image.asset(AppIcons.google,
                                          width: 48.w, height: 48.h),
                                      onPressed: () {
                                        Get.find<SettingsController>()
                                            .triggerFeedback();
                                        _safeSnackbar("Coming Soon",
                                            "Google sign-up not yet implemented.");
                                      },
                                    ),
                                    const SizedBox(width: 20),
                                    IconButton(
                                      icon: Image.asset(AppIcons.apple,
                                          width: 48, height: 48),
                                      onPressed: () {
                                        Get.find<SettingsController>()
                                            .triggerFeedback();
                                        _safeSnackbar(
                                          "Coming Soon",
                                          "Apple sign-up not yet implemented.",
                                        );
                                      },
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                // Bottom text
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Don't have an account? ",
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Get.find<SettingsController>()
                                            .triggerFeedback();
                                        Get.toNamed('/signup');
                                      },
                                      child: Text(
                                        "Create Account",
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.secondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                GestureDetector(
                                  onTap: () {
                                    Get.find<SettingsController>()
                                        .triggerFeedback();
                                    Get.toNamed('/forgot-password');
                                    },
                                  child: Text(
                                    "Forget password?",
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium?.copyWith(
                                      decoration: TextDecoration.underline,
                                      color: colorScheme.onSurface,
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
                  color: colorScheme.onPrimary),
              onPressed: () {
                Get.find<SettingsController>().triggerFeedback();
                Get.back();
              },
            ),
          ),
        ],
      ),
    );
  }
}
