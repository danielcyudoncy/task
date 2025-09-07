// widgets/image_picker_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Added import
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

  // Validate if the URL is a valid HTTP/HTTPS URL
  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _handleImageSelection(context),
          child: Obx(() {
            final profilePic = controller.profilePic.value;
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
              child: ClipOval(
                child: SizedBox(
                  width: radius * 2, // Ensure consistent sizing
                  height: radius * 2,
                  child: profilePic.isNotEmpty && _isValidUrl(profilePic)
                      ? CachedNetworkImage(
                          imageUrl: profilePic,
                          placeholder: (context, url) => CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryColor,
                            ),
                          ),
                          errorWidget: (context, url, error) => _buildFallbackAvatar(context),
                          imageBuilder: (context, imageProvider) => CircleAvatar(
                            radius: radius,
                            backgroundImage: imageProvider,
                            backgroundColor: Colors.grey[200],
                          ),
                        )
                      : _buildFallbackAvatar(context),
                ),
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
          child: Text(
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

  // Fallback avatar (camera icon or initials)
  Widget _buildFallbackAvatar(BuildContext context) {
    // Option 1: Keep camera icon as in original
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      child: Icon(
        Icons.camera_alt,
        size: iconSize,
        color: AppColors.primaryColor,
      ),
    );

    // Option 2: Use initials for consistency with AppDrawer/HeaderWidget (uncomment to use)
    /*
    final fullName = controller.fullName.value;
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.primaryColor,
          fontSize: iconSize * 0.8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    */
  }

  Future<void> _handleImageSelection(BuildContext context) async {
    try {
      final XFile? pickedImage = await _showImagePickerDialog(context);
      if (pickedImage != null) {
        if (kIsWeb) {
          // For web, read as bytes
          try {
            final bytes = await pickedImage.readAsBytes();
            await controller.uploadProfilePictureFromBytes(bytes, pickedImage.name);
          } catch (e) {
            SnackbarUtils.showSnackbar("Error", "Failed to read image: ${e.toString()}");
          }
        } else {
          // For mobile, use File
          try {
            final File imageFile = File(pickedImage.path);
            if (await imageFile.exists()) {
              await controller.uploadProfilePicture(imageFile);
            } else {
              SnackbarUtils.showSnackbar("Error", "Selected image doesn't exist");
            }
          } catch (e) {
            SnackbarUtils.showSnackbar("Error", "Failed to process image: ${e.toString()}");
          }
        }
      }
    } catch (e) {
      SnackbarUtils.showSnackbar("Error", "Failed to select image: ${e.toString()}");
    }
  }

  Future<XFile?> _showImagePickerDialog(BuildContext context) async {
    return await showDialog<XFile?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Center(child: Text('Pick an image')),
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
                  if (context.mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(picked);
                  } else {
                    Get.back(result: picked);
                  }
                } catch (e) {
                  if (context.mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Get.back();
                  }
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
            if (!kIsWeb)
              TextButton(
                onPressed: () async {
                  try {
                    final XFile? picked = await ImagePicker().pickImage(
                      source: ImageSource.camera,
                      maxWidth: 800,
                      maxHeight: 800,
                      imageQuality: 85,
                    );
                    if (context.mounted && Navigator.of(context).canPop()) {
                      Navigator.of(context).pop(picked);
                    } else {
                      Get.back(result: picked);
                    }
                  } catch (e) {
                    if (context.mounted && Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      Get.back();
                    }
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