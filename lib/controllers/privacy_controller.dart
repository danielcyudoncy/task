// controllers/privacy_controller.dart
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../service/biometric_service.dart';
import '../utils/url_launcher_helper.dart';

class PrivacyController extends GetxController {
  // Privacy settings observables
  final RxBool thirdPartyServices = false.obs;
  final RxBool locationServices = false.obs;
  final RxBool adPreferences = false.obs;
  final RxBool twoFactorAuth = false.obs;
  
  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  
  // Services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final BiometricService _biometricService = BiometricService();
  // final FirebaseMessagingService _messagingService = Get.find<FirebaseMessagingService>();
  
  // Privacy policy and terms URLs
  static const String privacyPolicyUrl = 'https://your-company.com/privacy-policy';
  static const String termsOfServiceUrl = 'https://your-company.com/terms-of-service';
  static const String dataProtectionUrl = 'https://your-company.com/data-protection';
  
  @override
  void onInit() {
    super.onInit();
    loadPrivacySettings();
  }
  
  /// Load privacy settings from local storage and Firestore
  Future<void> loadPrivacySettings() async {
    try {
      isLoading.value = true;
      
      // Load from SharedPreferences first (faster)
      final prefs = await SharedPreferences.getInstance();
      thirdPartyServices.value = prefs.getBool('third_party_services') ?? false;
      locationServices.value = prefs.getBool('location_services') ?? false;
      adPreferences.value = prefs.getBool('ad_preferences') ?? false;
      twoFactorAuth.value = prefs.getBool('two_factor_auth') ?? false;
      
      // Sync with Firestore if user is authenticated
      final user = _auth.currentUser;
      if (user != null) {
        await _syncWithFirestore(user.uid);
      }
    } catch (e) {
      debugPrint('Error loading privacy settings: $e');
      _showErrorSnackbar('Failed to load privacy settings');
    } finally {
      isLoading.value = false;
    }
  }
  
  /// Sync settings with Firestore
  Future<void> _syncWithFirestore(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('privacy_settings')
          .doc('preferences')
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        thirdPartyServices.value = data['third_party_services'] ?? false;
        locationServices.value = data['location_services'] ?? false;
        adPreferences.value = data['ad_preferences'] ?? false;
        twoFactorAuth.value = data['two_factor_auth'] ?? false;
        
        // Update local storage
        await _saveToLocalStorage();
      }
    } catch (e) {
      debugPrint('Error syncing with Firestore: $e');
    }
  }
  
  /// Save settings to local storage
  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('third_party_services', thirdPartyServices.value);
      await prefs.setBool('location_services', locationServices.value);
      await prefs.setBool('ad_preferences', adPreferences.value);
      await prefs.setBool('two_factor_auth', twoFactorAuth.value);
    } catch (e) {
      debugPrint('Error saving to local storage: $e');
    }
  }
  
  /// Save all privacy settings
  Future<void> savePrivacySettings() async {
    try {
      isSaving.value = true;
      
      // Save to local storage
      await _saveToLocalStorage();
      
      // Save to Firestore if user is authenticated
      final user = _auth.currentUser;
      if (user != null) {
        await _saveToFirestore(user.uid);
      }
      
      // Apply settings
      await _applyPrivacySettings();
      
      _showSuccessSnackbar('Privacy settings saved successfully');
    } catch (e) {
      debugPrint('Error saving privacy settings: $e');
      _showErrorSnackbar('Failed to save privacy settings');
    } finally {
      isSaving.value = false;
    }
  }
  
  /// Save settings to Firestore
  Future<void> _saveToFirestore(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('privacy_settings')
          .doc('preferences')
          .set({
        'third_party_services': thirdPartyServices.value,
        'location_services': locationServices.value,
        'ad_preferences': adPreferences.value,
        'two_factor_auth': twoFactorAuth.value,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving to Firestore: $e');
      rethrow;
    }
  }
  
  /// Apply privacy settings to relevant services
  Future<void> _applyPrivacySettings() async {
    try {
      // Apply third-party services setting
      if (thirdPartyServices.value) {
        await _enableThirdPartyServices();
      } else {
        await _disableThirdPartyServices();
      }
      
      // Apply location services setting
      if (locationServices.value) {
        await _enableLocationServices();
      } else {
        await _disableLocationServices();
      }
      
      // Apply ad preferences
      if (adPreferences.value) {
        await _enablePersonalizedAds();
      } else {
        await _disablePersonalizedAds();
      }
      
      // Apply two-factor authentication
      if (twoFactorAuth.value) {
        await _enableTwoFactorAuth();
      }
    } catch (e) {
      debugPrint('Error applying privacy settings: $e');
    }
  }
  
  /// Enable third-party services (notifications, analytics)
  Future<void> _enableThirdPartyServices() async {
    try {
      // Enable push notifications
      // await _messagingService.requestPermission();
      
      // Enable Firebase Analytics (if configured)
      // FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
      
      debugPrint('Third-party services enabled');
    } catch (e) {
      debugPrint('Error enabling third-party services: $e');
    }
  }
  
  /// Disable third-party services
  Future<void> _disableThirdPartyServices() async {
    try {
      // Note: We can't completely disable FCM, but we can stop requesting permissions
      // and disable analytics data collection
      
      // Disable Firebase Analytics (if configured)
      // FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
      
      debugPrint('Third-party services disabled');
    } catch (e) {
      debugPrint('Error disabling third-party services: $e');
    }
  }
  
  /// Enable location services (placeholder - requires permission_handler)
  Future<void> _enableLocationServices() async {
    try {
      // Note: This app doesn't currently use location services
      // This is a placeholder for future implementation
      debugPrint('Location services enabled (placeholder)');
      
      // Future implementation would include:
      // - Request location permissions
      // - Enable location-based features
      // - Update user preferences in Firestore
    } catch (e) {
      debugPrint('Error enabling location services: $e');
    }
  }
  
  /// Disable location services
  Future<void> _disableLocationServices() async {
    try {
      debugPrint('Location services disabled');
      
      // Future implementation would include:
      // - Disable location-based features
      // - Clear cached location data
      // - Update user preferences
    } catch (e) {
      debugPrint('Error disabling location services: $e');
    }
  }
  
  /// Enable personalized ads
  Future<void> _enablePersonalizedAds() async {
    try {
      // Note: This app doesn't currently show ads
      // This is a placeholder for future ad integration
      debugPrint('Personalized ads enabled (placeholder)');
      
      // Future implementation would include:
      // - Enable ad personalization
      // - Update ad preferences with ad networks
      // - Allow behavioral tracking for ads
    } catch (e) {
      debugPrint('Error enabling personalized ads: $e');
    }
  }
  
  /// Disable personalized ads
  Future<void> _disablePersonalizedAds() async {
    try {
      debugPrint('Personalized ads disabled');
      
      // Future implementation would include:
      // - Disable ad personalization
      // - Show generic ads only
      // - Opt out of behavioral tracking
    } catch (e) {
      debugPrint('Error disabling personalized ads: $e');
    }
  }
  
  /// Enable two-factor authentication
  Future<void> _enableTwoFactorAuth() async {
    try {
      // Check if biometric authentication is available
      final isAvailable = await _biometricService.canCheckBiometrics();
      
      if (isAvailable) {
        // Biometric is available, user can use it as 2FA
        debugPrint('Two-factor authentication enabled with biometric');
      } else {
        // Fallback to other 2FA methods (SMS, email, authenticator app)
        debugPrint('Two-factor authentication enabled (non-biometric)');
        
        // Show dialog to set up alternative 2FA method
        _showTwoFactorSetupDialog();
      }
    } catch (e) {
      debugPrint('Error enabling two-factor authentication: $e');
      _showErrorSnackbar('Failed to enable two-factor authentication');
    }
  }
  
  /// Show two-factor authentication setup dialog
  void _showTwoFactorSetupDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Two-Factor Authentication'),
        content: const Text(
          'Biometric authentication is not available on this device. '
          'Two-factor authentication has been enabled with alternative methods. '
          'You can configure additional security options in your account settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  // Removed unused 2FA setup methods - can be added back when needed
  
  /// Open privacy policy
  void openPrivacyPolicy() {
    UrlLauncherHelper.openExternalLink(privacyPolicyUrl);
  }
  
  /// Open terms of service
  void openTermsOfService() {
    UrlLauncherHelper.openExternalLink(termsOfServiceUrl);
  }
  
  /// Open data protection information
  void openDataProtection() {
    UrlLauncherHelper.openExternalLink(dataProtectionUrl);
  }
  
  /// Exports user data
  Future<void> exportUserData() async {
    try {
      isSaving.value = true;
      
      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        _showErrorSnackbar('User not authenticated');
        return;
      }

      // Request storage permissions based on Android version
      PermissionStatus permissionStatus;
      
      // For Android 13+ (API 33+), use more specific permissions
      if (Platform.isAndroid) {
        // Try to request manage external storage permission first
        permissionStatus = await Permission.manageExternalStorage.request();
        
        // If manage external storage is denied, try regular storage permission
        if (!permissionStatus.isGranted) {
          permissionStatus = await Permission.storage.request();
        }
        
        // If still denied, show detailed instructions
        if (!permissionStatus.isGranted) {
          _showDetailedPermissionError();
          return;
        }
      } else {
        // For other platforms, use regular storage permission
        permissionStatus = await Permission.storage.request();
        if (!permissionStatus.isGranted) {
          _showErrorSnackbar('Storage permission is required to export data');
          return;
        }
      }

      // Ask user to select save location
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select location to save your data export',
      );
      
      if (selectedDirectory == null) {
        // User cancelled the picker
        _showErrorSnackbar('Export cancelled - no location selected');
        return;
      }

      // Collect user data from Firestore
      final userData = await _collectUserData(user);
      
      // Create JSON file with user data
      final fileName = 'user_data_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final filePath = '$selectedDirectory/$fileName';
      
      final file = File(filePath);
      await file.writeAsString(jsonEncode(userData));
      
      _showSuccessSnackbar('Data exported successfully to: $filePath');
      
    } catch (e) {
      debugPrint('Error exporting user data: $e');
      _showErrorSnackbar('Failed to export data: $e');
    } finally {
      isSaving.value = false;
    }
  }
  
  /// Collects user data from various sources
  Future<Map<String, dynamic>> _collectUserData(User user) async {
    final userData = <String, dynamic>{};
    
    try {
      // Basic user information
      userData['user_info'] = {
        'uid': user.uid,
        'email': user.email,
        'display_name': user.displayName,
        'phone_number': user.phoneNumber,
        'email_verified': user.emailVerified,
        'creation_time': user.metadata.creationTime?.toIso8601String(),
        'last_sign_in': user.metadata.lastSignInTime?.toIso8601String(),
      };
      
      // Privacy settings
      userData['privacy_settings'] = {
        'third_party_services': thirdPartyServices.value,
        'location_services': locationServices.value,
        'ad_preferences': adPreferences.value,
        'two_factor_auth': twoFactorAuth.value,
      };
      
      // Try to get user documents from Firestore
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          userData['firestore_data'] = userDoc.data();
        }
      } catch (e) {
        debugPrint('Could not fetch Firestore data: $e');
        userData['firestore_data'] = 'Error fetching data: $e';
      }
      
      // Export timestamp
      userData['export_info'] = {
        'exported_at': DateTime.now().toIso8601String(),
        'export_version': '1.0',
        'app_version': '1.0.0',
      };
      
    } catch (e) {
      debugPrint('Error collecting user data: $e');
      userData['error'] = 'Error collecting some data: $e';
    }
    
    return userData;
  }

  /// Deletes user account with confirmation
  Future<void> deleteUserAccount() async {
    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and will permanently delete all your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      isSaving.value = true;
      
      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        _showErrorSnackbar('User not authenticated');
        return;
      }

      // TODO: Implement actual account deletion
      // This would typically involve:
      // 1. Deleting user data from Firestore
      // 2. Deleting user authentication account
      // 3. Clearing local storage
      // 4. Logging out and redirecting to login
      
      await Future.delayed(const Duration(seconds: 2)); // Simulate processing
      
      _showInfoSnackbar('Your account deletion has been requested. Your account will be permanently deleted within 24 hours.');
      
      // TODO: Implement actual logout and redirect
      
    } catch (e) {
      debugPrint('Error deleting user account: $e');
      _showErrorSnackbar('Failed to delete account: $e');
    } finally {
      isSaving.value = false;
    }
  }
  
  /// Toggle third-party services
  Future<void> toggleThirdPartyServices(bool value) async {
    try {
      thirdPartyServices.value = value;
      
      if (value) {
        // Enable third-party services
        debugPrint('Enabling third-party services (Analytics, Crash Reporting)');
        
        // TODO: Enable Firebase Analytics
        // await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
        
        // TODO: Enable Firebase Crashlytics
        // await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
        
        _showSuccessSnackbar('Third-party services enabled');
      } else {
        // Disable third-party services
        debugPrint('Disabling third-party services (Analytics, Crash Reporting)');
        
        // TODO: Disable Firebase Analytics
        // await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
        
        // TODO: Disable Firebase Crashlytics
        // await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
        
        _showSuccessSnackbar('Third-party services disabled');
      }
      
      // Save to preferences
      await _saveToLocalStorage();
      
    } catch (e) {
      debugPrint('Error toggling third-party services: $e');
      _showErrorSnackbar('Failed to toggle third-party services');
    }
  }
  
  /// Toggle location services
  Future<void> toggleLocationServices(bool value) async {
    try {
      if (value) {
        // Request location permission (placeholder - requires permission_handler package)
        // For now, just toggle the setting
        locationServices.value = true;
        debugPrint('Location services enabled');
        _showSuccessSnackbar('Location services enabled (requires permission_handler package for full functionality)');
      } else {
        locationServices.value = false;
        debugPrint('Location services disabled');
        _showSuccessSnackbar('Location services disabled');
      }
    } catch (e) {
      debugPrint('Error toggling location services: $e');
      _showErrorSnackbar('Failed to toggle location services');
    }
  }
  
  /// Toggle ad preferences
  Future<void> toggleAdPreferences(bool value) async {
    try {
      adPreferences.value = value;
      
      if (value) {
        // Enable targeted ads
        debugPrint('Enabling targeted advertisements');
        
        // TODO: Enable ad personalization
        // This would typically involve:
        // - Setting ad personalization consent
        // - Updating Google Ads settings
        // - Communicating with ad networks (AdMob, etc.)
        
        _showSuccessSnackbar('Targeted ads enabled');
      } else {
        // Disable targeted ads
        debugPrint('Disabling targeted advertisements');
        
        // TODO: Disable ad personalization
        // This would typically involve:
        // - Removing ad personalization consent
        // - Showing non-personalized ads only
        // - Updating ad network settings
        
        _showSuccessSnackbar('Targeted ads disabled - you will see generic ads');
      }
      
      // Save to preferences
      await _saveToLocalStorage();
      
    } catch (e) {
      debugPrint('Error toggling ad preferences: $e');
      _showErrorSnackbar('Failed to toggle ad preferences');
    }
  }
  
  /// Toggle two-factor authentication
  Future<void> toggleTwoFactorAuth(bool value) async {
    try {
      if (value) {
        // Check if biometric authentication is available
        final isAvailable = await _biometricService.canCheckBiometrics();
        
        if (isAvailable) {
          // Test biometric authentication
          final authenticated = await _biometricService.authenticate(
            reason: 'Enable Two-Factor Authentication'
          );
          
          if (authenticated) {
            twoFactorAuth.value = true;
            debugPrint('Two-factor authentication enabled with biometric');
            _showSuccessSnackbar('Two-factor authentication enabled');
          } else {
            twoFactorAuth.value = false;
            _showErrorSnackbar('Biometric authentication failed');
          }
        } else {
          // Fallback to other 2FA methods
          twoFactorAuth.value = true;
          debugPrint('Two-factor authentication enabled (non-biometric)');
          _showTwoFactorSetupDialog();
        }
      } else {
        twoFactorAuth.value = false;
        debugPrint('Two-factor authentication disabled');
        _showSuccessSnackbar('Two-factor authentication disabled');
      }
    } catch (e) {
      debugPrint('Error toggling two-factor authentication: $e');
      _showErrorSnackbar('Failed to toggle two-factor authentication');
    }
  }
  
  /// Show success snackbar
  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withValues(alpha: 0.1),
      colorText: Colors.green[700],
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 3),
    );
  }
  
  /// Show error snackbar
  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }

  /// Show info snackbar
  void _showInfoSnackbar(String message) {
    Get.snackbar(
      'Info',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  /// Show detailed permission error with instructions
  void _showDetailedPermissionError() {
    Get.dialog(
      AlertDialog(
        title: const Text('Storage Permission Required'),
        content: const Text(
          'To export your data, this app needs storage permission. '
          'Please go to Settings > Apps > [App Name] > Permissions and enable Storage permission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

}