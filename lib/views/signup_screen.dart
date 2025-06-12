// views/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: theme.brightness == Brightness.light
              ? const LinearGradient(
                  colors: [Colors.white, Color(0xFF2e3bb5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : LinearGradient(
                  colors: [colorScheme.surface, Colors.grey.shade900],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
        ),
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Scrollable Main Content
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, left: 25, right: 25),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Logo
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            AppIcons.logo,
                            height: 100,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Form Container
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: theme.brightness == Brightness.light
                              ? const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Text(
                                "Create Account",
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Adjust the content below to update your profile.",
                                style: textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),

                              // Full Name
                              _buildTextField(
                                context: context,
                                controller: fullNameController,
                                icon: Icons.person,
                                hint: "Full Name",
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Full Name cannot be empty";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Email
                              _buildTextField(
                                context: context,
                                controller: emailController,
                                icon: Icons.email,
                                hint: "Email",
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Email cannot be empty";
                                  }
                                  if (!GetUtils.isEmail(value)) {
                                    return "Enter a valid email";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Password
                              _buildTextField(
                                context: context,
                                controller: passwordController,
                                icon: Icons.lock,
                                hint: "Password",
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Password cannot be empty";
                                  }
                                  if (value.length < 6) {
                                    return "Password must be at least 6 characters";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Confirm Password
                              _buildTextField(
                                context: context,
                                controller: confirmPasswordController,
                                icon: Icons.lock,
                                hint: "Confirm Password",
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Please confirm your password";
                                  }
                                  if (value != passwordController.text) {
                                    return "Passwords do not match";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Role Dropdown
                              Obx(() => DropdownButtonFormField<String>(
                                    value: authController
                                            .selectedRole.value.isEmpty
                                        ? null
                                        : authController.selectedRole.value,
                                    icon: const Icon(Icons.arrow_drop_down),
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      hintText: "Select Role",
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
                                        return "Please select a role";
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
                              const SizedBox(height: 20),

                              // Sign Up Button
                              Obx(() => authController.isLoading.value
                                  ? const CircularProgressIndicator()
                                  : SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: colorScheme.primary,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: _signUp,
                                        child: Text(
                                          "Save & Continue",
                                          style: textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onPrimary,
                                          ),
                                        ),
                                      ),
                                    )),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    child: Text(
                                      "Or sign up with",
                                      style: textTheme.bodyMedium,
                                    ),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Google and Apple Buttons
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
                                        width: 48.w, height: 48.h),
                                    onPressed: () {
                                      Get.snackbar("Coming Soon",
                                          "Apple sign-up not yet implemented.");
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: textTheme.bodyMedium,
                                  ),
                                  GestureDetector(
                                    onTap: () => Get.toNamed('/login'),
                                    child: Text(
                                      "Sign In",
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
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
              // Back Arrow on Top Layer
              Positioned(
                top: 10,
                left: 20,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: colorScheme.primary),
                  onPressed: () {
                    Get.back(); // Navigates back to the previous screen
                  },
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

  void _signUp() {
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
