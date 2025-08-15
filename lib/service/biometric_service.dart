// service/biometric_service.dart
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canCheckBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      debugPrint('BiometricService: canCheckBiometrics=$canCheck, isDeviceSupported=$isSupported');
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
}