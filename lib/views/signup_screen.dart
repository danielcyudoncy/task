// views/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class SignUpScreen extends StatelessWidget {
  final AuthController authController = Get.put(AuthController());

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Create an Account",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Email Field
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            // Password Field
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),

            // Confirm Password Field
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Confirm Password"),
            ),

            const SizedBox(height: 20),

            // Role Selection Dropdown
            Obx(() => DropdownButton<String>(
                  value: authController.selectedRole.value.isEmpty
                      ? null
                      : authController.selectedRole.value,
                  hint: const Text("Select Role"),
                  isExpanded: true,
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

            // Sign Up Button with Loading State
            Obx(() => authController.isLoading.value
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () {
                      if (_validateInputs()) {
                        authController.signUp(
                          emailController.text.trim(),
                          passwordController.text.trim(),
                          authController.selectedRole.value,
                        );
                      }
                    },
                    child: const Text("Sign Up"),
                  )),
          ],
        ),
      ),
    );
  }

  // Validation Method
  bool _validateInputs() {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty ||
        authController.selectedRole.value.isEmpty) {
      Get.snackbar("Error", "All fields are required.");
      return false;
    }

    if (passwordController.text != confirmPasswordController.text) {
      Get.snackbar("Error", "Passwords do not match.");
      return false;
    }

    return true;
  }
}
