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
  final AuthController authController = Get.find();

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Upload Profile Picture",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _image == null
                ? const Icon(Icons.person, size: 100, color: Colors.grey)
                : Image.file(_image!,
                    height: 100, width: 100, fit: BoxFit.cover),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text("Choose Image"),
            ),
            const SizedBox(height: 20),
            Obx(() => authController.isLoading.value
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () {
                      if (_image != null) {
                        authController.uploadProfilePicture(_image!);
                      } else {
                        Get.snackbar("Error", "Please select an image");
                      }
                    },
                    child: const Text("Upload"),
                  )),
          ],
        ),
      ),
    );
  }
}
