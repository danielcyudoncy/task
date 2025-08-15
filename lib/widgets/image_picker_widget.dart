// widgets/image_picker_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/auth_controller.dart';
import '../utils/constants/app_colors.dart';
import '../utils/snackbar_utils.dart';
import 'package:flutter/foundation.dart';

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
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.onPrimary
                      : Colors.white,
                  width: 2,
                ),
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
          child:  Text(
            'Change Photo',
            style: TextStyle(
              color: AppColors.black,
              fontSize: 16.sp,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleImageSelection(BuildContext context) async {
    try {
      debugPrint("ImagePickerWidget: Starting image selection");
      final XFile? pickedImage = await _showImagePickerDialog(context);
      if (pickedImage != null) {
        debugPrint("ImagePickerWidget: Image selected - ${pickedImage.name}");
        
        if (kIsWeb) {
          // For web, read as bytes
          try {
            debugPrint("ImagePickerWidget: Reading image as bytes for web");
            final bytes = await pickedImage.readAsBytes();
            debugPrint("ImagePickerWidget: Image bytes read successfully, size: ${bytes.length}");
            await controller.uploadProfilePictureFromBytes(bytes, pickedImage.name);
          } catch (e) {
            debugPrint("ImagePickerWidget: Failed to read image bytes: $e");
            SnackbarUtils.showSnackbar("Error", "Failed to read image: ${e.toString()}");
          }
        } else {
          // For mobile, use File
          try {
            debugPrint("ImagePickerWidget: Processing image file for mobile");
            final File imageFile = File(pickedImage.path);
            if (await imageFile.exists()) {
              final fileSize = await imageFile.length();
              debugPrint("ImagePickerWidget: Image file exists, size: $fileSize bytes");
              await controller.uploadProfilePicture(imageFile);
            } else {
              debugPrint("ImagePickerWidget: Selected image file doesn't exist");
              SnackbarUtils.showSnackbar("Error", "Selected image doesn't exist");
            }
          } catch (e) {
            debugPrint("ImagePickerWidget: Failed to process image file: $e");
            SnackbarUtils.showSnackbar("Error", "Failed to process image: ${e.toString()}");
          }
        }
      } else {
        debugPrint("ImagePickerWidget: No image selected");
      }
    } catch (e) {
      debugPrint("ImagePickerWidget: Failed to select image: $e");
      SnackbarUtils.showSnackbar("Error", "Failed to select image: ${e.toString()}");
    }
  }

  Future<XFile?> _showImagePickerDialog(BuildContext context) async {
    return await showDialog<XFile?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text('Pick an image')),
          actionsAlignment: MainAxisAlignment.center,
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
                }
              },
              child: Text(
                'Gallery',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!kIsWeb) TextButton(
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
                }
              },
              child: Text(
                'Camera',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
