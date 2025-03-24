// views/profile_update_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/auth_controller.dart';
import 'dart:io';

class ProfileUpdateScreen extends StatefulWidget {
  const ProfileUpdateScreen({super.key});
  

  @override
  ProfileUpdateScreenState createState() => ProfileUpdateScreenState();
}


class ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  File? _image;
  final AuthController authController = Get.find<AuthController>();

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to pick an image.");
    }
  }

  // Function to upload the selected image
  Future<void> _uploadImage() async {
    if (_image == null) {
      Get.snackbar("Error", "Please select an image first.");
      return;
    }

    await authController.uploadProfilePicture(_image!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display User's Full Name
            Obx(() => Text(
                  "Welcome, ${authController.fullName.value}!",
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                )),
            const SizedBox(height: 20),

            // Profile Image Preview - Now using the profilePic observable
            Obx(() {
              return CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey,
                backgroundImage: _image != null
                    ? FileImage(_image!) as ImageProvider
                    : (authController.profilePic.value.isNotEmpty
                        ? NetworkImage(authController.profilePic.value)
                        : null),
                child: _image == null && authController.profilePic.value.isEmpty
                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              );
            }),

            const SizedBox(height: 20),

            // Button to Pick Image
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text("Choose Image"),
            ),

            const SizedBox(height: 20),

            // Upload Button with Loading Indicator
            Obx(() => authController.isLoading.value
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _uploadImage,
                    icon: const Icon(Icons.upload),
                    label: const Text("Upload"),
                  )),

            const SizedBox(height: 20),

            // Continue to Home button
            ElevatedButton(
              onPressed: () => Get.offAllNamed('/home'),
              child: const Text("Continue to Home"),
            ),
          ],
        ),
      ),
    );
  }
}
