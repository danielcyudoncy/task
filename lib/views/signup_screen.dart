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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Create an Account",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(labelText: "Confirm Password"),
              obscureText: true,
            ),
            Obx(() => DropdownButton<String>(
                  value: authController.selectedRole.value.isEmpty
                      ? null
                      : authController.selectedRole.value,
                  hint: const Text("Select Role"),
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
            Obx(() => authController.isLoading.value
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () {
                      if (passwordController.text ==
                              confirmPasswordController.text &&
                          authController.selectedRole.value.isNotEmpty) {
                        authController.signUp(
                          emailController.text.trim(),
                          passwordController.text.trim(),
                          authController.selectedRole.value,
                        );
                      } else {
                        Get.snackbar("Error",
                            "Passwords do not match or Role not selected");
                      }
                    },
                    child: const Text("Sign Up"),
                  )),
          ],
        ),
      ),
    );
  }
}
