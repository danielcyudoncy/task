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
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to pick an image: ${e.toString()}");
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
      appBar: AppBar(title: const Text("Update Profile Picture")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Upload Profile Picture",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Profile Image Preview
            _image == null
                ? const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  )
                : CircleAvatar(
                    radius: 50,
                    backgroundImage: FileImage(_image!),
                  ),

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
          ],
        ),
      ),
    );
  }
}
