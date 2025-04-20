// widgets/image_picker_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/auth_controller.dart';
import '../utils/constants/app_colors.dart';

class ImagePickerWidget extends StatelessWidget {
  final AuthController controller;
  final double radius;
  final double iconSize;

  const ImagePickerWidget({
    super.key,
    required this.controller,
    this.radius = 60,
    this.iconSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _handleImageSelection(context),
          child: Obx(() {
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: controller.profilePic.value.isEmpty
                    ? Border.all(color: AppColors.primaryColor, width: 2)
                    : null,
              ),
              child: CircleAvatar(
                radius: radius,
                backgroundColor: Colors.grey[200],
                backgroundImage: controller.profilePic.value.isNotEmpty
                    ? NetworkImage(controller.profilePic.value)
                    : null,
                child: controller.profilePic.value.isEmpty
                    ? Icon(Icons.camera_alt,
                        size: iconSize, color: AppColors.primaryColor)
                    : null,
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => _handleImageSelection(context),
          style: TextButton.styleFrom(
            backgroundColor: Colors.grey[300],
            side: const BorderSide(color: Colors.blue, width: 1),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Change Photo',
            style: TextStyle(
              color: AppColors.black,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleImageSelection(BuildContext context) async {
    try {
      final XFile? pickedImage = await _showImagePickerDialog(context);
      if (pickedImage != null) {
        final File imageFile = File(pickedImage.path);
        if (await imageFile.exists()) {
          await controller.uploadProfilePicture(imageFile);
        } else {
          Get.snackbar("Error", "Selected image doesn't exist");
        }
      }
    } catch (e) {
      debugPrint("Image selection error: $e");
      Get.snackbar("Error", "Failed to select image: ${e.toString()}");
    }
  }

  Future<XFile?> _showImagePickerDialog(BuildContext context) async {
    return await showDialog<XFile?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick an image'),
          actions: [
            TextButton(
              onPressed: () async {
                try {
                  final XFile? picked = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 800,
                    maxHeight: 800,
                    imageQuality: 85,
                  );
                  if (context.mounted) Navigator.of(context).pop(picked);
                } catch (e) {
                  if (context.mounted) Navigator.of(context).pop();
                  debugPrint("Gallery pick error: $e");
                }
              },
              child: const Text('Gallery'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final XFile? picked = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                    maxWidth: 800,
                    maxHeight: 800,
                    imageQuality: 85,
                  );
                  if (context.mounted) Navigator.of(context).pop(picked);
                } catch (e) {
                  if (context.mounted) Navigator.of(context).pop();
                  debugPrint("Camera pick error: $e");
                }
              },
              child: const Text('Camera'),
            ),
          ],
        );
      },
    );
  }
}
