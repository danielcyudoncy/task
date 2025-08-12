// controllers/app_lock_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task/service/biometric_service.dart';
import 'package:task/controllers/auth_controller.dart';

class AppLockController extends GetxController with WidgetsBindingObserver {
  static AppLockController get to => Get.find<AppLockController>();
  
  final BiometricService _biometricService = BiometricService();
  final AuthController _authController = Get.find<AuthController>();
  
  // Observable variables
  final RxBool isAppLocked = false.obs;
  final RxBool isAppLockEnabled = true.obs;
  final RxBool isBiometricEnabled = true.obs;
  final RxString appPin = ''.obs;
  final RxBool hasSetPin = false.obs;
  final RxBool isUsingDefaultPin = true.obs;
  
  // Default PIN for first-time users
  static const String defaultPin = '0000';
  
  // App lifecycle state
  AppLifecycleState? _lastLifecycleState;
  DateTime? _backgroundTime;
  
  // Lock timeout (in seconds) - app locks immediately when minimized for security
  static const int lockTimeoutSeconds = 1;
  
  // Getter for current lifecycle state (useful for debugging and monitoring)
  AppLifecycleState? get currentLifecycleState => _lastLifecycleState;
  
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
  }
  
  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('App lifecycle state changed from $_lastLifecycleState to $state');
    
    // Only process state changes if this is a meaningful transition
    if (_lastLifecycleState != state) {
      switch (state) {
        case AppLifecycleState.paused:
        case AppLifecycleState.inactive:
          _handleAppPaused(state);
          break;
        case AppLifecycleState.resumed:
          _handleAppResumed();
          break;
        case AppLifecycleState.detached:
          // App is being terminated - ensure any cleanup
          _handleAppDetached();
          break;
        case AppLifecycleState.hidden:
          // App is hidden but still running
          _handleAppPaused(state);
          break;
      }
      
      _lastLifecycleState = state;
    }
  }
  
  void _handleAppPaused(AppLifecycleState currentState) {
    if (isAppLockEnabled.value && _authController.currentUser != null) {
      _backgroundTime = DateTime.now();
      debugPrint('App went to background (state: $currentState) at: $_backgroundTime');
      
      // Lock immediately when app is minimized for enhanced security
      if (currentState == AppLifecycleState.paused || currentState == AppLifecycleState.hidden) {
        debugPrint('App minimized - locking immediately for security');
        _lockApp();
      } else if (_lastLifecycleState == AppLifecycleState.resumed) {
        debugPrint('App transitioned from active to background - starting lock timer');
      } else if (_lastLifecycleState == AppLifecycleState.inactive) {
        debugPrint('App moved from inactive to paused/hidden');
      }
    }
  }
  
  void _handleAppResumed() {
    if (isAppLockEnabled.value && 
        _authController.currentUser != null && 
        _backgroundTime != null) {
      
      final timeInBackground = DateTime.now().difference(_backgroundTime!);
      debugPrint('App resumed from $_lastLifecycleState after: ${timeInBackground.inSeconds} seconds');
      
      // Enhanced logic based on previous state
      bool shouldLock = false;
      
      if (_lastLifecycleState == AppLifecycleState.paused || 
          _lastLifecycleState == AppLifecycleState.hidden) {
        // App was fully backgrounded - apply full timeout
        shouldLock = timeInBackground.inSeconds >= lockTimeoutSeconds;
      } else if (_lastLifecycleState == AppLifecycleState.inactive) {
        // App was briefly inactive (e.g., notification overlay) - shorter timeout
        shouldLock = timeInBackground.inSeconds >= (lockTimeoutSeconds ~/ 2);
      }
      
      if (shouldLock) {
        debugPrint('Locking app due to timeout from state: $_lastLifecycleState');
        _lockApp();
      } else {
        debugPrint('App resumed within timeout period - no lock required');
      }
      
      _backgroundTime = null;
    } else if (_lastLifecycleState == AppLifecycleState.paused || 
               _lastLifecycleState == AppLifecycleState.hidden) {
      // App was backgrounded but no background time recorded (edge case)
      debugPrint('App resumed from background but no timestamp - applying precautionary lock');
      if (isAppLockEnabled.value && _authController.currentUser != null) {
        _lockApp();
      }
    }
  }
  
  void _handleAppDetached() {
    debugPrint('App is being terminated - performing cleanup');
    
    // Clear sensitive data when app is being terminated
    _backgroundTime = null;
    
    // If app lock is enabled, ensure the app will be locked on next startup
    if (isAppLockEnabled.value && _authController.currentUser != null) {
      debugPrint('App terminated while locked - will require unlock on restart');
    }
  }
  
  void _lockApp() {
    debugPrint('Locking app');
    isAppLocked.value = true;
    
    // Navigate to app lock screen
    Get.offAllNamed('/app-lock');
  }
  
  Future<void> unlockWithPin(String pin) async {
    // Check if PIN matches (either user's PIN or default PIN)
    bool isCorrectPin = false;
    
    if (hasSetPin.value && pin == appPin.value) {
      isCorrectPin = true;
    } else if (!hasSetPin.value && pin == defaultPin) {
      isCorrectPin = true;
      isUsingDefaultPin.value = true;
    }
    
    if (isCorrectPin) {
      _unlockApp();
      
      // Show warning if using default PIN
      if (isUsingDefaultPin.value) {
        Future.delayed(const Duration(milliseconds: 500), () {
          Get.snackbar(
            'Security Warning',
            'You are using the default PIN (0000). Please change it in Settings for better security.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
        });
      }
    } else {
      Get.snackbar(
        'Error',
        'Incorrect PIN. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  Future<void> unlockWithBiometric() async {
    if (!isBiometricEnabled.value) {
      Get.snackbar(
        'Error',
        'Biometric authentication is disabled.',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    
    if (!await _biometricService.canCheckBiometrics()) {
      Get.snackbar(
        'Error',
        'Biometric authentication is not available on this device.',
        snackPosition: SnackPosition.TOP,
      );
      return;
    }
    
    final authenticated = await _biometricService.authenticate(
      reason: 'Please authenticate to unlock the app'
    );
    
    if (authenticated) {
      _unlockApp();
    } else {
      Get.snackbar(
        'Error',
        'Biometric authentication failed.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
  
  void _unlockApp() {
    debugPrint('Unlocking app');
    isAppLocked.value = false;
    
    // Navigate back to appropriate screen based on user role
    _authController.navigateBasedOnRole();
  }
  
  Future<void> setPin(String pin) async {
    appPin.value = pin;
    hasSetPin.value = true;
    isUsingDefaultPin.value = false;
    await _saveSettings();
    
    Get.snackbar(
      'Success',
      'PIN has been set successfully.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }
  
  Future<void> changePin(String oldPin, String newPin) async {
    if (oldPin != appPin.value) {
      Get.snackbar(
        'Error',
        'Current PIN is incorrect.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    await setPin(newPin);
  }
  
  Future<void> toggleAppLock(bool enabled) async {
    isAppLockEnabled.value = enabled;
    await _saveSettings();
  }
  
  Future<void> toggleBiometric(bool enabled) async {
    isBiometricEnabled.value = enabled;
    await _saveSettings();
  }
  
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      isAppLockEnabled.value = prefs.getBool('app_lock_enabled') ?? true;
      isBiometricEnabled.value = prefs.getBool('biometric_enabled') ?? true;
      appPin.value = prefs.getString('app_pin') ?? '';
      hasSetPin.value = appPin.value.isNotEmpty;
      isUsingDefaultPin.value = prefs.getBool('is_using_default_pin') ?? true;
      
      debugPrint('App lock settings loaded');
    } catch (e) {
      debugPrint('Error loading app lock settings: $e');
    }
  }
  
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('app_lock_enabled', isAppLockEnabled.value);
      await prefs.setBool('biometric_enabled', isBiometricEnabled.value);
      await prefs.setString('app_pin', appPin.value);
      await prefs.setBool('is_using_default_pin', isUsingDefaultPin.value);
      
      debugPrint('App lock settings saved');
    } catch (e) {
      debugPrint('Error saving app lock settings: $e');
    }
  }
  
  // Force lock the app (can be called manually)
  void lockAppManually() {
    if (_authController.currentUser != null) {
      _lockApp();
    }
  }
  
  // Check if app should be locked on startup
  bool shouldLockOnStartup() {
    return isAppLockEnabled.value && 
           _authController.currentUser != null;
  }
}