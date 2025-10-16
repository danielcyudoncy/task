// examples/update_integration_example.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../service/update_service.dart';
import '../service/version_service.dart';
import '../widgets/update_dialog.dart';

/// Example of how to integrate the update mechanism into your app
class UpdateIntegrationExample extends StatefulWidget {
  const UpdateIntegrationExample({super.key});

  @override
  State<UpdateIntegrationExample> createState() =>
      _UpdateIntegrationExampleState();
}

class _UpdateIntegrationExampleState extends State<UpdateIntegrationExample>
    with WidgetsBindingObserver {
  bool _isCheckingForUpdates = false;
  Map<String, dynamic>? _updateStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize update service
    _initializeUpdateService();

    // Check for updates when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdatesOnStartup();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Check for updates when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _checkForUpdatesInBackground();
    }
  }

  Future<void> _initializeUpdateService() async {
    await UpdateService.initialize();
  }

  Future<void> _checkForUpdatesOnStartup() async {
    // Check for updates silently on app startup
    await UpdateService.checkForUpdates(
      forceCheck: false,
      showDialog: true,
    );
  }

  Future<void> _checkForUpdatesInBackground() async {
    // Background check - shows subtle notifications
    await UpdateService.checkForUpdatesInBackground();
  }

  Future<void> _checkForUpdatesManually() async {
    setState(() {
      _isCheckingForUpdates = true;
    });

    try {
      await UpdateService.checkForUpdates(
        forceCheck: true,
        showDialog: true,
      );

      // Get update status for display
      final status = await UpdateService.getUpdateStatus();
      setState(() {
        _updateStatus = status;
      });

      if (!status['hasUpdate']) {
        Get.snackbar(
          'No Updates',
          'You are using the latest version of the app.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to check for updates: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isCheckingForUpdates = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Integration Example'),
        actions: [
          IconButton(
            onPressed: UpdateService.showUpdateSettings,
            icon: const Icon(Icons.settings),
            tooltip: 'Update Settings',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isCheckingForUpdates
                          ? null
                          : _checkForUpdatesManually,
                      icon: _isCheckingForUpdates
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(
                        _isCheckingForUpdates
                            ? 'Checking...'
                            : 'Check for Updates',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: UpdateService.showUpdateSettings,
                      icon: const Icon(Icons.settings),
                      label: const Text('Update Settings'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _showCustomUpdateDialog,
                      icon: const Icon(Icons.preview),
                      label: const Text('Preview Update Dialog'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_updateStatus != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Update Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildStatusItem(
                        'Platform',
                        _updateStatus!['platform'] ?? 'Unknown',
                      ),
                      _buildStatusItem(
                        'Has Update',
                        _updateStatus!['hasUpdate'].toString(),
                      ),
                      _buildStatusItem(
                        'Auto Update',
                        _updateStatus!['autoUpdateEnabled'].toString(),
                      ),
                      _buildStatusItem(
                        'Check Frequency',
                        _updateStatus!['frequency'] ?? 'Unknown',
                      ),
                      if (_updateStatus!['updateInfo'] != null) ...[
                        const Divider(),
                        const Text(
                          'Available Update:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildStatusItem(
                          'Current Version',
                          _updateStatus!['updateInfo']['currentVersion'] ??
                              'Unknown',
                        ),
                        _buildStatusItem(
                          'Latest Version',
                          _updateStatus!['updateInfo']['latestVersion'] ??
                              'Unknown',
                        ),
                        _buildStatusItem(
                          'Forced Update',
                          _updateStatus!['updateInfo']['isForced'].toString(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const Spacer(),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Integration Tips',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Call UpdateService.initialize() in your main() function\n'
                      '• Check for updates on app startup and resume\n'
                      '• Use background checks for subtle notifications\n'
                      '• Customize update dialogs for your app\'s design\n'
                      '• Test with different update scenarios',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomUpdateDialog() {
    // Show a preview of the update dialog with mock data
    final mockUpdateInfo = UpdateInfo(
      currentVersion: '1.0.0',
      latestVersion: '1.1.0',
      isForced: false,
      releaseNotes: 'This is a preview of the update dialog.\n\n'
          '• New features added\n'
          '• Bug fixes and improvements\n'
          '• Enhanced user experience',
    );

    UpdateDialog.show(
      updateInfo: mockUpdateInfo,
      forceUpdate: false,
      onUpdate: () {
        Get.snackbar(
          'Update',
          'Update action triggered (this is a preview)',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      onSkip: () {
        Get.snackbar(
          'Skipped',
          'Update skipped (this is a preview)',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      onLater: () {
        Get.snackbar(
          'Later',
          'Update postponed (this is a preview)',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
  }
}
