// service/android_update_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:get/get.dart';

class AndroidUpdateService {
  static bool _isUpdateInProgress = false;
  
  /// Check for Android in-app updates
  static Future<void> checkForAndroidUpdate({
    bool showDialog = true,
    bool forceUpdate = false,
  }) async {
    if (!Platform.isAndroid || _isUpdateInProgress) return;
    
    try {
      // Check if update is available through Google Play
      final updateInfo = await InAppUpdate.checkForUpdate();
      
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (showDialog) {
          _showUpdateDialog(
            updateInfo: updateInfo,
            forceUpdate: forceUpdate,
          );
        } else {
          // Start update immediately
          await _startUpdate(updateInfo, forceUpdate);
        }
      }
    } catch (e) {
    }
  }
  
  /// Show update dialog
  static void _showUpdateDialog({
    required AppUpdateInfo updateInfo,
    required bool forceUpdate,
  }) {
    Get.dialog(
      AlertDialog(
        title: const Text('Update Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('A new version of the app is available.'),
            const SizedBox(height: 8),
            if (updateInfo.availableVersionCode != null)
              Text(
                'Version: ${updateInfo.availableVersionCode}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 8),
            const Text('Would you like to update now?'),
          ],
        ),
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Later'),
            ),
          TextButton(
            onPressed: () {
              Get.back();
              _startUpdate(updateInfo, forceUpdate);
            },
            child: const Text('Update'),
          ),
        ],
      ),
      barrierDismissible: !forceUpdate,
    );
  }
  
  /// Start the update process
  static Future<void> _startUpdate(
    AppUpdateInfo updateInfo,
    bool forceUpdate,
  ) async {
    if (_isUpdateInProgress) return;
    
    _isUpdateInProgress = true;
    
    try {
      if (forceUpdate || updateInfo.immediateUpdateAllowed) {
        // Immediate update - app will restart after update
        await _startImmediateUpdate();
      } else if (updateInfo.flexibleUpdateAllowed) {
        // Flexible update - user can continue using app while downloading
        await _startFlexibleUpdate();
      }
    } catch (e) {
      _showUpdateError();
    } finally {
      _isUpdateInProgress = false;
    }
  }
  
  /// Start immediate update
  static Future<void> _startImmediateUpdate() async {
    try {
      final result = await InAppUpdate.performImmediateUpdate();
      
      switch (result) {
        case AppUpdateResult.success:
          break;
        case AppUpdateResult.userDeniedUpdate:
          break;
        case AppUpdateResult.inAppUpdateFailed:
          _showUpdateError();
          break;
      }
    } catch (e) {
      _showUpdateError();
    }
  }
  
  /// Start flexible update
  static Future<void> _startFlexibleUpdate() async {
    try {
      final result = await InAppUpdate.startFlexibleUpdate();
      
      switch (result) {
        case AppUpdateResult.success:
          _listenForFlexibleUpdateCompletion();
          break;
        case AppUpdateResult.userDeniedUpdate:
          break;
        case AppUpdateResult.inAppUpdateFailed:
          _showUpdateError();
          break;
      }
    } catch (e) {
      _showUpdateError();
    }
  }
  
  /// Listen for flexible update completion
  static void _listenForFlexibleUpdateCompletion() {
    // Show snackbar to notify user that update is ready
    _showUpdateCompletedSnackbar();
  }
  
  /// Show update completed snackbar
  static void _showUpdateCompletedSnackbar() {
    Get.snackbar(
      'Update Ready',
      'Restart the app to complete the update',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
      mainButton: TextButton(
        onPressed: () async {
          await InAppUpdate.completeFlexibleUpdate();
        },
        child: const Text(
          'RESTART',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
  
  /// Show update error
  static void _showUpdateError() {
    Get.snackbar(
      'Update Failed',
      'Failed to update the app. Please try again later.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }
  
  /// Check if flexible update is downloaded and ready to install
  static Future<bool> isFlexibleUpdateDownloaded() async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      return updateInfo.installStatus == InstallStatus.downloaded;
    } catch (e) {
      return false;
    }
  }
  
  /// Complete flexible update (restart app)
  static Future<void> completeFlexibleUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
    }
  }
}