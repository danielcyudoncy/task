# In-App Update Implementation Guide

This guide explains how to implement and use the in-app update mechanism in your Flutter app.

## Overview

The in-app update system provides:
- **Android**: Google Play In-App Updates (immediate and flexible)
- **iOS**: App Store redirect with custom dialogs
- **Cross-platform**: Unified API and customizable UI
- **Smart scheduling**: Configurable update check frequency
- **User preferences**: Settings for update behavior

## Quick Start

### 1. Dependencies

The following dependencies are already added to `pubspec.yaml`:
```yaml
dependencies:
  in_app_update: ^4.2.2        # Android in-app updates
  package_info_plus: ^4.2.0    # Version checking
  url_launcher: ^6.3.2         # iOS App Store redirect
  shared_preferences: ^2.2.2   # User preferences
  http: ^1.1.0                 # Version checking API
  get: ^4.6.6                  # State management & dialogs
```

### 2. Basic Integration

```dart
import 'package:flutter/material.dart';
import 'service/update_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize update service
  await UpdateService.initialize();
  
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Check for updates on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdates();
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Background check when app resumes
      UpdateService.checkForUpdatesInBackground();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}
```

### 3. Manual Update Check

```dart
// Force check for updates
ElevatedButton(
  onPressed: () {
    UpdateService.checkForUpdates(
      forceCheck: true,
      showDialog: true,
    );
  },
  child: Text('Check for Updates'),
)
```

### 4. Update Settings

```dart
// Show update settings dialog
IconButton(
  onPressed: UpdateService.showUpdateSettings,
  icon: Icon(Icons.settings),
)
```

## Configuration

### Android Setup

1. **Google Play Console**: Ensure your app is published on Google Play
2. **App Signing**: Use Play App Signing for in-app updates to work
3. **Testing**: Use internal testing tracks to test updates

### iOS Setup

1. **App Store ID**: Update the App Store ID in `ios_update_service.dart`:
```dart
static const String _appStoreId = 'YOUR_APP_STORE_ID';
```

2. **URL Schemes**: Ensure `url_launcher` permissions in `ios/Runner/Info.plist`:
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>itms-apps</string>
</array>
```

### Version Checking API

Update the version checking endpoint in `version_service.dart`:
```dart
static const String _versionCheckUrl = 'https://your-api.com/version-check';
```

Expected API response:
```json
{
  "latest_version": "1.2.0",
  "minimum_version": "1.0.0",
  "force_update": false,
  "release_notes": "Bug fixes and improvements"
}
```

## Usage Examples

### Custom Update Dialog

```dart
import 'widgets/update_dialog.dart';
import 'service/version_service.dart';

// Show custom update dialog
void showCustomUpdateDialog() {
  final updateInfo = UpdateInfo(
    currentVersion: '1.0.0',
    latestVersion: '1.1.0',
    isForced: false,
    releaseNotes: 'New features and improvements',
  );
  
  UpdateDialog.show(
    updateInfo: updateInfo,
    onUpdate: () {
      // Handle update action
      UpdateService.checkForUpdates(showDialog: false);
    },
    onSkip: () {
      // Handle skip action
      print('Update skipped');
    },
  );
}
```

### Background Update Checks

```dart
// Check for updates in background (shows subtle notifications)
Timer.periodic(Duration(hours: 6), (timer) {
  UpdateService.checkForUpdatesInBackground();
});
```

### Update Status Information

```dart
// Get current update status
final status = await UpdateService.getUpdateStatus();
print('Has update: ${status['hasUpdate']}');
print('Platform: ${status['platform']}');
print('Auto update enabled: ${status['autoUpdateEnabled']}');
```

## Testing

### Android Testing

1. **Internal Testing**:
   - Upload APK to internal testing track
   - Install from Play Store
   - Upload newer version
   - Test in-app update flow

2. **Fake Update**:
   ```bash
   # Enable fake update for testing
   adb shell am start -n "com.google.android.fakestore/.MainActivity"
   ```

### iOS Testing

1. **TestFlight**:
   - Upload build to TestFlight
   - Test App Store redirect
   - Verify update prompts

2. **Simulator Testing**:
   - Test with mock version data
   - Verify dialog behavior
   - Test App Store URL handling

## Customization

### Update Frequency Options

```dart
// Available frequencies in UpdateService
static const Map<String, int> updateFrequencies = {
  'Never': -1,
  'Daily': 24,
  'Weekly': 168,
  'Monthly': 720,
};
```

### Custom UI Themes

```dart
// Customize update dialog appearance
UpdateDialog.show(
  updateInfo: updateInfo,
  // Add custom styling through theme
);
```

### Version Comparison Logic

```dart
// Custom version comparison in VersionService
static int compareVersions(String version1, String version2) {
  // Implement custom version comparison logic
  // Current implementation uses semantic versioning
}
```

## Best Practices

### 1. Update Timing
- Check for updates on app startup
- Perform background checks when app resumes
- Respect user preferences for frequency
- Avoid interrupting critical user flows

### 2. User Experience
- Use non-intrusive notifications for optional updates
- Clearly communicate forced updates
- Provide meaningful release notes
- Allow users to postpone non-critical updates

### 3. Error Handling
- Handle network failures gracefully
- Provide fallback options
- Log errors for debugging
- Show user-friendly error messages

### 4. Testing Strategy
- Test both immediate and flexible updates
- Verify forced update scenarios
- Test network failure cases
- Validate on different Android versions

## Troubleshooting

### Common Issues

1. **Android Updates Not Working**:
   - Ensure app is installed from Google Play
   - Check Play Console for app signing
   - Verify update availability in Play Console

2. **iOS App Store Not Opening**:
   - Verify App Store ID is correct
   - Check URL scheme permissions
   - Test on physical device

3. **Version Check Failures**:
   - Verify API endpoint is accessible
   - Check network connectivity
   - Validate API response format

### Debug Information

```dart
// Enable debug logging
UpdateService.checkForUpdates(
  forceCheck: true,
  showDialog: true,
).then((_) {
  print('Update check completed');
}).catchError((error) {
  print('Update check failed: $error');
});
```

## Security Considerations

1. **API Security**: Use HTTPS for version check endpoints
2. **Certificate Pinning**: Consider pinning certificates for API calls
3. **Input Validation**: Validate all API responses
4. **User Privacy**: Respect user preferences and privacy settings

## Performance

1. **Background Checks**: Use efficient background checking
2. **Caching**: Cache version information appropriately
3. **Network Usage**: Minimize unnecessary network calls
4. **Battery Impact**: Consider battery usage in background checks

## Migration Guide

If you're migrating from an existing update system:

1. **Backup Current Implementation**: Save your existing update code
2. **Update Dependencies**: Add required packages to `pubspec.yaml`
3. **Initialize Service**: Add `UpdateService.initialize()` to your main function
4. **Replace Update Calls**: Replace existing update checks with `UpdateService.checkForUpdates()`
5. **Test Thoroughly**: Verify all update scenarios work correctly

## Support

For issues and questions:
1. Check the troubleshooting section above
2. Review the example implementation in `examples/update_integration_example.dart`
3. Test with the provided example app
4. Verify your configuration matches the setup requirements