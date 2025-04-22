// views/login_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/auth_social_button.dart';
import 'package:task/utils/constants/app_colors.dart';
import 'package:task/utils/constants/app_icons.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthController _auth = Get.find();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Color(0xFF2e3bb5),
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

                        // White box container
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  "Welcome Back",
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                        fontFamily: 'Poppins',
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Fill out the information below in order to access your account.",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),

                                // Email Field
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: "Email",
                                    prefixIcon: const Icon(Icons.email),
                                    filled: true,
                                    fillColor: Colors.grey[200],
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
                                  decoration: InputDecoration(
                                    labelText: "Password",
                                    prefixIcon: const Icon(Icons.lock),
                                    filled: true,
                                    fillColor: Colors.grey[200],
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
                                          foregroundColor: Colors.white,
                                          backgroundColor:
                                              AppColors.primaryColor,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: _submit,
                                        child: const Text(
                                          "Sign In",
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      )),

                                const SizedBox(height: 24),

                                // Divider with text
                                const Row(
                                  children: [
                                    Expanded(child: Divider()),
                                    Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8),
                                      child: Text("or continue with"),
                                    ),
                                    Expanded(child: Divider()),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Animated Google & Apple Login Buttons
                                AuthSocialButton(
                                  label: 'Continue with Google',
                                  isGoogle: true,
                                  onTap: () {
                                    // TODO: Trigger Google Sign-In
                                  },
                                ),
                                AuthSocialButton(
                                  label: 'Continue with Apple',
                                  isGoogle: false,
                                  onTap: () {
                                    // TODO: Trigger Apple Sign-In
                                  },
                                ),

                                const SizedBox(height: 24),

                                // Bottom text
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Don't have an account? "),
                                    GestureDetector(
                                      onTap: () => Get.toNamed('/signup'),
                                      child: const Text(
                                        "Create Account",
                                        style: TextStyle(
                                          color: AppColors.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),

                                GestureDetector(
                                  onTap: () {
                                    // TODO: Navigate to Forgot Password screen
                                  },
                                  child: const Text(
                                    "Forget password?",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      color: AppColors.black,
                                      fontWeight: FontWeight.bold,
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
              icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
              onPressed: () {
                Get.back(); // Navigates back to the previous screen
              },
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _auth.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    }
  }
}
