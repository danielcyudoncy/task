import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task/service/version_service.dart';
import 'package:task/service/update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Mock SharedPreferences for testing
  SharedPreferences.setMockInitialValues({});
  
  // Mock package_info_plus plugin
  const MethodChannel('dev.fluttercommunity.plus/package_info')
      .setMockMethodCallHandler((MethodCall methodCall) async {
    if (methodCall.method == 'getAll') {
      return <String, dynamic>{
        'appName': 'Test App',
        'packageName': 'com.example.test',
        'version': '1.0.0',
        'buildNumber': '1',
      };
    }
    return null;
  });
  group('Update Service Tests', () {
    test('UpdateInfo can be created with valid data', () {
      final updateInfo = UpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '1.1.0',
        isForced: false,
        releaseNotes: 'Test release notes',
      );
      
      expect(updateInfo.currentVersion, '1.0.0');
      expect(updateInfo.latestVersion, '1.1.0');
      expect(updateInfo.isForced, false);
      expect(updateInfo.releaseNotes, 'Test release notes');
    });
    
    test('Version service can get current version', () async {
      // Test that we can get the current version
      final version = await VersionService.getCurrentVersion();
      expect(version, equals('1.0.0'));
    });
    
    test('Update frequency options are valid', () {
      final frequencies = UpdateService.updateFrequencies;
      
      expect(frequencies.containsKey('Never'), true);
      expect(frequencies.containsKey('Daily'), true);
      expect(frequencies.containsKey('Weekly'), true);
      expect(frequencies.containsKey('Monthly'), true);
      
      expect(frequencies['Never'], -1);
      expect(frequencies['Daily'], 24);
      expect(frequencies['Weekly'], 168);
      expect(frequencies['Monthly'], 720);
    });
    
    test('UpdateInfo handles null release notes', () {
      final updateInfo = UpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '1.1.0',
        isForced: true,
        releaseNotes: null,
      );
      
      expect(updateInfo.releaseNotes, null);
      expect(updateInfo.isForced, true);
    });
    
    test('Version service can get build number', () async {
      // Test that we can get the current build number
      final buildNumber = await VersionService.getCurrentBuildNumber();
      expect(buildNumber, equals('1'));
    });
    
    test('Forced update detection works', () {
      final forcedUpdate = UpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '2.0.0',
        isForced: true,
        releaseNotes: 'Critical security update',
      );
      
      final optionalUpdate = UpdateInfo(
        currentVersion: '1.0.0',
        latestVersion: '1.0.1',
        isForced: false,
        releaseNotes: 'Minor improvements',
      );
      
      expect(forcedUpdate.isForced, true);
      expect(optionalUpdate.isForced, false);
    });
  });
  
  group('Version Service Integration', () {
    test('Skip version functionality', () async {
      await VersionService.skipVersion('1.0.0');
      // Test passes if no exception is thrown
      expect(true, isTrue);
    });

    test('Update check timestamp', () async {
      await VersionService.updateLastCheckTime();
      // Test passes if no exception is thrown
      expect(true, isTrue);
    });
  });
}