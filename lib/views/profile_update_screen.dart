// views/profile_update_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/auth_controller.dart';
import 'dart:io';

class ProfileUpdateScreen extends StatefulWidget {
  const ProfileUpdateScreen({super.key});

  @override
  State<ProfileUpdateScreen> createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  final AuthController _auth = Get.find();
  final _picker = ImagePicker();
  File? _selectedImage;

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _selectedImage = File(pickedFile.path));
      }
    } catch (e) {
      Get.snackbar("Error", "Image selection failed");
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) {
      Get.snackbar("Notice", "Please select an image first");
      return;
    }
    await _auth.uploadProfilePicture(_selectedImage!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => Get.offAllNamed('/home'),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Obx(() => Text(
                  "Hi, ${_auth.fullName.value}",
                  style: Theme.of(context).textTheme.headlineSmall,
                )),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _pickImage,
              child: Obx(() => CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (_auth.profilePic.value.isNotEmpty
                            ? NetworkImage(_auth.profilePic.value)
                            : null),
                    child:
                        _selectedImage == null && _auth.profilePic.value.isEmpty
                            ? const Icon(Icons.add_a_photo, size: 40)
                            : null,
                  )),
            ),
            const SizedBox(height: 20),
            Text(
              _selectedImage == null && _auth.profilePic.value.isEmpty
                  ? "Add profile photo"
                  : "Change photo",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 40),
            Obx(() => _auth.isLoading.value
                ? const CircularProgressIndicator()
                : FilledButton(
                    onPressed: _uploadImage,
                    child: const Text("Save Profile"),
                  )),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Get.offAllNamed('/home'),
              child: const Text("Skip for now"),
            ),
          ],
        ),
      ),
    );
  }
}
