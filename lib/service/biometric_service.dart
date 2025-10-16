// service/biometric_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

class BiometricService extends GetxService {
  static BiometricService get to => Get.find<BiometricService>();
  final LocalAuthentication _auth = LocalAuthentication();

  // Observable variables
  final RxBool isBiometricAvailable = false.obs;
  final RxList<BiometricType> availableBiometrics = <BiometricType>[].obs;

  @override
  void onInit() {
    super.onInit();
    _checkBiometricAvailability();
  }

  @override
  void onReady() {
    super.onReady();
    // Double-check availability when service is ready
    _checkBiometricAvailability();
  }

  /// Check and update biometric availability
  Future<void> _checkBiometricAvailability() async {
    try {
      debugPrint('BiometricService: Checking biometric availability...');

      final canCheck = await _auth.canCheckBiometrics;
      debugPrint('BiometricService: canCheckBiometrics = $canCheck');

      final isSupported = await _auth.isDeviceSupported();
      debugPrint('BiometricService: isDeviceSupported = $isSupported');

      final biometrics = await _auth.getAvailableBiometrics();
      debugPrint('BiometricService: getAvailableBiometrics = $biometrics');

      final isAvailable = canCheck && isSupported && biometrics.isNotEmpty;

      isBiometricAvailable.value = isAvailable;
      availableBiometrics.value = biometrics;

      debugPrint('BiometricService: Final availability = $isAvailable');
      debugPrint('BiometricService: Available types = $biometrics');
    } catch (e) {
      debugPrint('BiometricService: Error checking availability: $e');
      isBiometricAvailable.value = false;
      availableBiometrics.clear();
    }
  }

  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      final biometrics = await _auth.getAvailableBiometrics();

      debugPrint(
          'BiometricService: canCheckBiometrics=$canCheck, isDeviceSupported=$isSupported');
      debugPrint('BiometricService: Available biometrics: $biometrics');

      // Check if any biometric is available (fingerprint, face, or other)
      if (biometrics.isEmpty) {
        debugPrint('BiometricService: No biometrics available');
        return false;
      }

      return canCheck && isSupported;
    } catch (e) {
      debugPrint('BiometricService: Error in canCheckBiometrics: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final biometrics = await _auth.getAvailableBiometrics();
      debugPrint('BiometricService: Available biometrics: $biometrics');
      return biometrics;
    } catch (e) {
      debugPrint('BiometricService: Error getting available biometrics: $e');
      return [];
    }
  }

  Future<bool> authenticate(
      {String reason = 'Please authenticate to unlock the app',
      bool biometricOnly = false}) async {
    try {
      debugPrint('BiometricService: Starting authentication check...');

      // First check if we can use biometrics
      final canCheck = await _auth.canCheckBiometrics;
      debugPrint('BiometricService: canCheckBiometrics = $canCheck');

      final isSupported = await _auth.isDeviceSupported();
      debugPrint('BiometricService: isDeviceSupported = $isSupported');

      final availableBiometrics = await _auth.getAvailableBiometrics();
      debugPrint(
          'BiometricService: availableBiometrics = $availableBiometrics');

      if (!canCheck || !isSupported) {
        debugPrint('BiometricService: Device does not support biometrics');
        return false;
      }

      if (availableBiometrics.isEmpty) {
        debugPrint('BiometricService: No biometrics enrolled on device');
        return false;
      }

      debugPrint(
          'BiometricService: Starting authentication with reason: $reason, biometricOnly: $biometricOnly');

      const authMessages = [
        AndroidAuthMessages(
          signInTitle: 'Biometric Authentication Required',
          biometricHint: 'Touch the fingerprint sensor',
          biometricNotRecognized: 'Fingerprint not recognized. Try again.',
          biometricRequiredTitle: 'Fingerprint Required',
          biometricSuccess: 'Fingerprint recognized successfully',
          cancelButton: 'Use PIN',
          deviceCredentialsRequiredTitle: 'Device Credentials Required',
          deviceCredentialsSetupDescription: 'Device credentials required',
          goToSettingsButton: 'Go to Settings',
          goToSettingsDescription:
              'Biometric authentication is not set up on your device. Go to Settings > Security to add biometric authentication.',
        ),
        IOSAuthMessages(
          lockOut:
              'Biometric authentication is disabled. Please lock and unlock your screen to enable it again.',
          goToSettingsButton: 'Go to Settings',
          goToSettingsDescription:
              'Biometric authentication is not set up on your device. Go to Settings > Touch ID & Passcode to add a fingerprint.',
          cancelButton: 'Use PIN',
        ),
      ];

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        authMessages: authMessages,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
          useErrorDialogs: true, // Show system error dialogs
          sensitiveTransaction: true, // Treat as sensitive operation
        ),
      );

      debugPrint('BiometricService: Authentication result: $didAuthenticate');
      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint(
          'BiometricService: Platform exception: ${e.code} - ${e.message}');

      // Handle specific error codes and show user-friendly messages
      switch (e.code) {
        case auth_error.notAvailable:
          debugPrint(
              'BiometricService: Biometric authentication not available');
          _showErrorSnackbar(
              'Biometric authentication is not available on this device');
          break;
        case auth_error.notEnrolled:
          debugPrint('BiometricService: No biometrics enrolled on device');
          _showErrorSnackbar(
              'No biometrics enrolled. Please set up fingerprint or face unlock in device settings');
          break;
        case auth_error.lockedOut:
          debugPrint('BiometricService: Biometric authentication locked out');
          _showErrorSnackbar(
              'Biometric authentication is temporarily locked. Please try again later');
          break;
        case auth_error.permanentlyLockedOut:
          debugPrint(
              'BiometricService: Biometric authentication permanently locked out');
          _showErrorSnackbar(
              'Biometric authentication is permanently locked. Please use device passcode');
          break;
        default:
          debugPrint('BiometricService: Unknown platform exception: ${e.code}');
          if (e.code != 'UserCancel') {
            // Don't show error for user cancellation
            _showErrorSnackbar('Biometric authentication failed: ${e.message}');
          }
      }
      return false;
    } catch (e) {
      debugPrint('BiometricService: Authentication error: $e');
      _showErrorSnackbar(
          'An unexpected error occurred during biometric authentication');
      return false;
    }
  }

  /// Get the primary biometric icon for UI display
  IconData getBiometricIcon() {
    if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else if (availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    } else if (availableBiometrics.contains(BiometricType.iris)) {
      return Icons.visibility;
    } else {
      return Icons.security;
    }
  }

  /// Get user-friendly string for available biometric types
  String getBiometricTypeString() {
    if (availableBiometrics.isEmpty) return 'None';

    List<String> types = [];

    if (availableBiometrics.contains(BiometricType.fingerprint)) {
      types.add('Fingerprint');
    }
    if (availableBiometrics.contains(BiometricType.face)) {
      types.add('Face ID');
    }
    if (availableBiometrics.contains(BiometricType.iris)) {
      types.add('Iris');
    }
    if (availableBiometrics.contains(BiometricType.strong)) {
      types.add('Strong Biometric');
    }
    if (availableBiometrics.contains(BiometricType.weak)) {
      types.add('Weak Biometric');
    }

    return types.join(', ');
  }

  /// Refresh biometric availability (useful after settings changes)
  Future<void> refreshBiometricAvailability() async {
    await _checkBiometricAvailability();
  }

  /// Show error snackbar
  void _showErrorSnackbar(String message) {
    if (Get.context != null) {
      Get.snackbar(
        'Biometric Error',
        message,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// Debug method to test biometric functionality
  Future<Map<String, dynamic>> debugBiometricStatus() async {
    final result = <String, dynamic>{};

    try {
      result['canCheckBiometrics'] = await _auth.canCheckBiometrics;
      result['isDeviceSupported'] = await _auth.isDeviceSupported();
      result['availableBiometrics'] = await _auth.getAvailableBiometrics();

      debugPrint('BiometricService Debug: $result');
    } catch (e) {
      result['error'] = e.toString();
      debugPrint('BiometricService Debug Error: $e');
    }

    return result;
  }

  /// Check if biometric authentication is properly set up
  Future<String> getBiometricStatus() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      final availableBiometrics = await _auth.getAvailableBiometrics();

      if (!isSupported) {
        return 'Device does not support biometric authentication';
      }

      if (!canCheck) {
        return 'Biometric authentication not available';
      }

      if (availableBiometrics.isEmpty) {
        return 'No biometric methods enrolled on device';
      }

      return 'Biometric authentication ready';
    } catch (e) {
      return 'Error checking biometric status: $e';
    }
  }
}
