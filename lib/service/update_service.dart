// service/update_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'version_service.dart';
import 'android_update_service.dart';
import 'ios_update_service.dart';

class UpdateService {
  static const String _lastUpdateCheckKey = 'last_update_check';
  static const String _updateFrequencyKey = 'update_check_frequency';
  static const String _autoUpdateEnabledKey = 'auto_update_enabled';

  // Update check frequency options (in hours)
  static const Map<String, int> updateFrequencies = {
    'Never': -1,
    'Daily': 24,
    'Weekly': 168,
    'Monthly': 720,
  };

  /// Initialize update service
  static Future<void> initialize() async {
    await _setDefaultPreferences();
  }

  /// Check for updates based on platform
  static Future<void> checkForUpdates({
    bool forceCheck = false,
    bool showDialog = true,
    bool forceUpdate = false,
  }) async {
    try {
      if (!forceCheck && !await _shouldCheckForUpdate()) {
        return;
      }

      if (showDialog) {
        final gitHubUpdate = await VersionService.checkGitHubRelease();
        if (gitHubUpdate != null) {
          await _showGitHubUpdateDialog(gitHubUpdate);
        }
      }

      await _updateLastCheckTime();

      if (Platform.isAndroid) {
        await AndroidUpdateService.checkForAndroidUpdate(
          showDialog: showDialog,
          forceUpdate: forceUpdate,
        );
      } else if (Platform.isIOS) {
        await IOSUpdateService.checkForIOSUpdate(
          showDialog: showDialog,
          forceUpdate: forceUpdate,
        );
      }
    } catch (e) {
      if (showDialog) {
        _showUpdateError();
      }
    }
  }

  /// Check for updates silently (background check)
  static Future<void> checkForUpdatesInBackground() async {
    try {
      final updateInfo = await VersionService.checkForUpdate();

      if (updateInfo != null) {
        // Show a subtle notification
        if (Platform.isIOS) {
          IOSUpdateService.showUpdateReminder(updateInfo);
        }
        // For Android, we'll use the in-app update mechanism directly
        // when the user opens the app next time
      }
    } catch (e) {
      debugPrint('Background update check failed: $e');
      // Continue silently - background checks shouldn't interrupt user experience
    }
  }

  /// Set update check frequency
  static Future<void> setUpdateFrequency(String frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_updateFrequencyKey, frequency);
  }

  /// Get current update frequency
  static Future<String> getUpdateFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_updateFrequencyKey) ?? 'Weekly';
  }

  /// Enable/disable auto updates
  static Future<void> setAutoUpdateEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoUpdateEnabledKey, enabled);
  }

  /// Check if auto updates are enabled
  static Future<bool> isAutoUpdateEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoUpdateEnabledKey) ?? true;
  }

  /// Show update settings dialog
  static void showUpdateSettings() {
    Get.dialog(
      AlertDialog(
        title: const Text('Update Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<String>(
              future: getUpdateFrequency(),
              builder: (context, snapshot) {
                final currentFrequency = snapshot.data ?? 'Weekly';
                return DropdownButtonFormField<String>(
                  initialValue: currentFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Check for updates',
                  ),
                  items: updateFrequencies.keys.map((String frequency) {
                    return DropdownMenuItem<String>(
                      value: frequency,
                      child: Text(frequency),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setUpdateFrequency(newValue);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            FutureBuilder<bool>(
              future: isAutoUpdateEnabled(),
              builder: (context, snapshot) {
                final isEnabled = snapshot.data ?? true;
                return SwitchListTile(
                  title: const Text('Auto-update notifications'),
                  subtitle: const Text(
                      'Show notifications when updates are available'),
                  value: isEnabled,
                  onChanged: (bool value) {
                    setAutoUpdateEnabled(value);
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              checkForUpdates(forceCheck: true);
            },
            child: const Text('Check Now'),
          ),
        ],
      ),
    );
  }

  /// Check if we should perform an update check
  static Future<bool> _shouldCheckForUpdate() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if auto updates are disabled
    if (!await isAutoUpdateEnabled()) {
      return false;
    }

    final frequency = await getUpdateFrequency();
    final frequencyHours = updateFrequencies[frequency] ?? 168;

    // If frequency is "Never", don't check
    if (frequencyHours == -1) {
      return false;
    }

    final lastCheck = prefs.getInt(_lastUpdateCheckKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final hoursSinceLastCheck = (now - lastCheck) / (1000 * 60 * 60);

    return hoursSinceLastCheck >= frequencyHours;
  }

  /// Update last check timestamp
  static Future<void> _updateLastCheckTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _lastUpdateCheckKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Set default preferences
  static Future<void> _setDefaultPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    if (!prefs.containsKey(_updateFrequencyKey)) {
      await prefs.setString(_updateFrequencyKey, 'Weekly');
    }

    if (!prefs.containsKey(_autoUpdateEnabledKey)) {
      await prefs.setBool(_autoUpdateEnabledKey, true);
    }
  }

  static Future<void> _showGitHubUpdateDialog(UpdateInfo updateInfo) async {
    await Get.dialog(
      AlertDialog(
        title: const Text('GitHub Update Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version (${updateInfo.latestVersion}) is available on GitHub.',
            ),
            const SizedBox(height: 8),
            Text(
              'Current version: ${updateInfo.currentVersion}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (updateInfo.releaseNotes != null &&
                updateInfo.releaseNotes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  updateInfo.releaseNotes!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
            },
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await _openGitHubReleases();
            },
            child: const Text('View on GitHub'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  static Future<void> _openGitHubReleases() async {
    try {
      final uri = Uri.parse(VersionService.githubReleaseUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showUpdateError();
      }
    } catch (e) {
      _showUpdateError();
    }
  }

  /// Show update error
  static void _showUpdateError() {
    Get.snackbar(
      'Update Check Failed',
      'Unable to check for updates. Please try again later.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  /// Get update status info
  static Future<Map<String, dynamic>> getUpdateStatus() async {
    try {
      final updateInfo = await VersionService.checkForUpdate();
      final frequency = await getUpdateFrequency();
      final autoUpdateEnabled = await isAutoUpdateEnabled();

      return {
        'hasUpdate': updateInfo != null,
        'updateInfo': updateInfo != null
            ? {
                'currentVersion': updateInfo.currentVersion,
                'latestVersion': updateInfo.latestVersion,
                'isForced': updateInfo.isForced,
                'releaseNotes': updateInfo.releaseNotes,
              }
            : null,
        'frequency': frequency,
        'autoUpdateEnabled': autoUpdateEnabled,
        'platform': Platform.operatingSystem,
      };
    } catch (e) {
      return {
        'hasUpdate': false,
        'error': e.toString(),
        'frequency': await getUpdateFrequency(),
        'autoUpdateEnabled': await isAutoUpdateEnabled(),
        'platform': Platform.operatingSystem,
      };
    }
  }
}
