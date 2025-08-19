// service/biometric_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      final biometrics = await _auth.getAvailableBiometrics();
      
      debugPrint('BiometricService: canCheckBiometrics=$canCheck, isDeviceSupported=$isSupported');
      debugPrint('BiometricService: Available biometrics: $biometrics');
      
      // Only return true if we specifically have fingerprint capability
      if (!biometrics.contains(BiometricType.fingerprint)) {
        debugPrint('BiometricService: No fingerprint biometric available');
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

  Future<bool> authenticate({String reason = 'Please authenticate to continue', bool biometricOnly = false}) async {
    try {
      debugPrint('BiometricService: Starting authentication with reason: $reason, biometricOnly: $biometricOnly');
      
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
        ),
      );
      
      debugPrint('BiometricService: Authentication result: $didAuthenticate');
      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('BiometricService: Platform exception: ${e.code} - ${e.message}');
      
      // Handle specific error codes
      switch (e.code) {
        case auth_error.notAvailable:
          debugPrint('BiometricService: Biometric authentication not available');
          break;
        case auth_error.notEnrolled:
          debugPrint('BiometricService: No biometrics enrolled on device');
          break;
        case auth_error.lockedOut:
          debugPrint('BiometricService: Biometric authentication locked out');
          break;
        case auth_error.permanentlyLockedOut:
          debugPrint('BiometricService: Biometric authentication permanently locked out');
          break;
        default:
          debugPrint('BiometricService: Unknown platform exception: ${e.code}');
      }
      return false;
    } catch (e) {
      debugPrint('BiometricService: Authentication error: $e');
      return false;
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