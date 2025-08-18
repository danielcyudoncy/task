import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../service/version_service.dart';
import '../service/update_service.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;
  final bool forceUpdate;
  final VoidCallback? onUpdate;
  final VoidCallback? onSkip;
  final VoidCallback? onLater;
  
  const UpdateDialog({
    Key? key,
    required this.updateInfo,
    this.forceUpdate = false,
    this.onUpdate,
    this.onSkip,
    this.onLater,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.system_update,
            color: Theme.of(context).primaryColor,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Text(
            'Update Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version (${updateInfo.latestVersion}) is available.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Current version: ${updateInfo.currentVersion}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if (updateInfo.releaseNotes != null && updateInfo.releaseNotes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'What\'s New:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  updateInfo.releaseNotes!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
            if (updateInfo.isForced || forceUpdate) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This update is required to continue using the app.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: _buildActions(context),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    );
  }
  
  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[];
    
    // Add "Later" button if not forced
    if (!forceUpdate && !updateInfo.isForced) {
      actions.add(
        TextButton(
          onPressed: () {
            Get.back();
            onLater?.call();
          },
          child: Text(
            'Later',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }
    
    // Add "Skip" button if not forced
    if (!forceUpdate && !updateInfo.isForced) {
      actions.add(
        TextButton(
          onPressed: () {
            Get.back();
            VersionService.skipVersion(updateInfo.latestVersion);
            onSkip?.call();
          },
          child: Text(
            'Skip',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }
    
    // Add "Update" button
    actions.add(
      ElevatedButton(
        onPressed: () {
          Get.back();
          if (onUpdate != null) {
            onUpdate!();
          } else {
            _defaultUpdateAction();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Update',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
    
    return actions;
  }
  
  void _defaultUpdateAction() {
    // Default update action - delegate to UpdateService
    UpdateService.checkForUpdates(
      forceCheck: true,
      showDialog: false,
    );
  }
  
  /// Show update dialog
  static void show({
    required UpdateInfo updateInfo,
    bool forceUpdate = false,
    VoidCallback? onUpdate,
    VoidCallback? onSkip,
    VoidCallback? onLater,
  }) {
    Get.dialog(
      UpdateDialog(
        updateInfo: updateInfo,
        forceUpdate: forceUpdate,
        onUpdate: onUpdate,
        onSkip: onSkip,
        onLater: onLater,
      ),
      barrierDismissible: !forceUpdate && !updateInfo.isForced,
    );
  }
}

/// Update notification widget for subtle notifications
class UpdateNotification extends StatelessWidget {
  final UpdateInfo updateInfo;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  
  const UpdateNotification({
    Key? key,
    required this.updateInfo,
    this.onTap,
    this.onDismiss,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.system_update,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update Available',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version ${updateInfo.latestVersion} is ready to install',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}