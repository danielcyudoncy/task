// views/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

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
      appBar: AppBar(title: const Text("Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Create an Account",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // ✅ Full Name Field
              TextFormField(
                controller: fullNameController,
                keyboardType: TextInputType.name,
                decoration: const InputDecoration(labelText: "Full Name"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Full Name cannot be empty";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 10),

              // ✅ Email Field
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "Email"),
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

              const SizedBox(height: 10),

              // ✅ Password Field
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "Password"),
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

              const SizedBox(height: 10),

              // ✅ Confirm Password Field
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: "Confirm Password"),
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

              const SizedBox(height: 20),

              // ✅ Role Selection Dropdown
              Obx(() => DropdownButtonFormField<String>(
                    value: authController.selectedRole.value.isEmpty
                        ? null
                        : authController.selectedRole.value,
                    hint: const Text("Select Role"),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "Role",
                      border: OutlineInputBorder(),
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

              // ✅ Sign Up Button with Validation
              Obx(() => authController.isLoading.value
                  ? const CircularProgressIndicator()
                  : Column(
                      children: [
                        ElevatedButton(
                          onPressed: _signUp,
                          child: const Text("Sign Up"),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            if (authController.auth.currentUser != null) {
                              Get.offNamed("/profile-update");
                            } else {
                              Get.snackbar(
                                  "Error", "Please complete signup first");
                            }
                          },
                          child: const Text("Continue to Profile Setup"),
                        ),
                      ],
                    )),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Sign Up Function with Full Name
  void _signUp() {
    if (_formKey.currentState!.validate()) {
      authController.signUp(
        fullNameController.text.trim(), // Pass Full Name
        emailController.text.trim(),
        passwordController.text.trim(),
        authController.selectedRole.value,
      );
    }
  }
}
