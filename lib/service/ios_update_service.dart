import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'version_service.dart';

class IOSUpdateService {
  // Replace with your actual App Store ID
  static const String _appStoreId = '1234567890';
  static const String _appStoreUrl =
      'https://apps.apple.com/app/id$_appStoreId';
  static const String _appStoreReviewUrl =
      'https://apps.apple.com/app/id$_appStoreId?action=write-review';

  /// Check for iOS updates
  static Future<void> checkForIOSUpdate({
    bool showDialog = true,
    bool forceUpdate = false,
  }) async {
    if (!Platform.isIOS) return;

    try {
      final updateInfo = await VersionService.checkForUpdate();

      if (updateInfo != null) {
        if (showDialog) {
          _showUpdateDialog(
            updateInfo: updateInfo,
            forceUpdate: forceUpdate,
          );
        } else {
          // Redirect to App Store immediately
          await _openAppStore();
        }
      }
    } catch (e) {
      debugPrint('Error checking for iOS update: $e');
    }
  }

  /// Show update dialog for iOS
  static void _showUpdateDialog({
    required UpdateInfo updateInfo,
    required bool forceUpdate,
  }) {
    Get.dialog(
      AlertDialog(
        title: const Text('Update Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version (${updateInfo.latestVersion}) is available on the App Store.',
            ),
            const SizedBox(height: 8),
            Text(
              'Current version: ${updateInfo.currentVersion}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (updateInfo.releaseNotes != null) ...[
              const SizedBox(height: 12),
              const Text(
                'What\'s New:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                updateInfo.releaseNotes!,
                style: const TextStyle(fontSize: 12),
              ),
            ],
            if (updateInfo.isForced) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This update is required to continue using the app.',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!forceUpdate && !updateInfo.isForced)
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Later'),
            ),
          if (!forceUpdate && !updateInfo.isForced)
            TextButton(
              onPressed: () {
                Get.back();
                VersionService.skipVersion(updateInfo.latestVersion);
              },
              child: const Text('Skip'),
            ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _openAppStore();
            },
            child: const Text('Update'),
          ),
        ],
      ),
      barrierDismissible: !forceUpdate && !updateInfo.isForced,
    );
  }

  /// Open App Store for update
  static Future<void> _openAppStore() async {
    try {
      final uri = Uri.parse(_appStoreUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showAppStoreError();
      }
    } catch (e) {
      debugPrint('Error opening App Store: $e');
      _showAppStoreError();
    }
  }

  /// Open App Store review page
  static Future<void> openAppStoreReview() async {
    try {
      final uri = Uri.parse(_appStoreReviewUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showAppStoreError();
      }
    } catch (e) {
      debugPrint('Error opening App Store review: $e');
      _showAppStoreError();
    }
  }

  /// Show App Store error
  static void _showAppStoreError() {
    Get.snackbar(
      'Error',
      'Unable to open App Store. Please update manually.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  /// Show update reminder
  static void showUpdateReminder(UpdateInfo updateInfo) {
    Get.snackbar(
      'Update Available',
      'Version ${updateInfo.latestVersion} is available',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          _showUpdateDialog(
            updateInfo: updateInfo,
            forceUpdate: false,
          );
        },
        child: const Text(
          'UPDATE',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  /// Check if app was recently updated
  static Future<bool> wasRecentlyUpdated() async {
    try {
      // This is a simple check - you might want to implement
      // more sophisticated logic based on your needs
      // You could store the last known version and compare
      // For now, this is a placeholder
      return false;
    } catch (e) {
      return false;
    }
  }
}
