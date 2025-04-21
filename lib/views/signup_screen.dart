// views/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/auth_social_button.dart';
import '../controllers/auth_controller.dart';
import '../utils/constants/app_colors.dart';
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFF2e3bb5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Adjust the content below to update your profile.",
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Full Name
                        _buildTextField(
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
                              value: authController.selectedRole.value.isEmpty
                                  ? null
                                  : authController.selectedRole.value,
                              icon: const Icon(Icons.arrow_drop_down),
                              isExpanded: true,
                              decoration: InputDecoration(
                                hintText: "Select Role",
                                prefixIcon: const Icon(Icons.person_outline),
                                filled: true,
                                fillColor: Colors.grey[200],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please select a role";
                                }
                                return null;
                              },
                              onChanged: (String? value) {
                                authController.selectedRole.value = value!;
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
                                    backgroundColor: AppColors.primaryColor,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _signUp,
                                  child: const Text(
                                    "Save & Continue",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )),
                        const SizedBox(height: 20),

                        const Text("Or sign up with"),
                        const SizedBox(height: 16),

                        // Google and Apple Buttons
                        Column(
                          children: [
                            AuthSocialButton(
                              label: "Continue with Google",
                              isGoogle: true,
                              onTap: () {
                                Get.snackbar("Coming Soon",
                                    "Google sign-up not yet implemented.");
                              },
                            ),
                            AuthSocialButton(
                              label: "Continue with Apple",
                              isGoogle: false,
                              onTap: () {
                                Get.snackbar("Coming Soon",
                                    "Apple sign-up not yet implemented.");
                              },
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey[200],
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
