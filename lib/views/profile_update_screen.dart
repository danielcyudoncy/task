// views/profile_update_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../service/firebase_service.dart';

class ProfileUpdateScreen extends StatefulWidget {
  const ProfileUpdateScreen({super.key});

  @override
  State<ProfileUpdateScreen> createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  final AuthController _auth = Get.find();
  final FirebaseService _firebaseService = Get.find();
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complete Your Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Phone Number"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your phone number";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: "Bio"),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              Obx(() => _auth.isLoading.value
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitProfile,
                      child: const Text("Complete Profile"),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        _auth.isLoading(true);

        // Save profile data
        await _firebaseService.updateUserData(_auth.auth.currentUser!.uid, {
          "phone": _phoneController.text,
          "bio": _bioController.text,
          "profileComplete": true,
        });

        // Complete the profile process
        await _auth.completeProfile();
      } catch (e) {
        Get.snackbar("Error", "Failed to update profile: ${e.toString()}");
      } finally {
        _auth.isLoading(false);
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
