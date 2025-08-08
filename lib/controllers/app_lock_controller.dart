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
  
  // App lifecycle state
  AppLifecycleState? _lastLifecycleState;
  DateTime? _backgroundTime;
  
  // Lock timeout (in seconds) - app locks after 30 seconds in background
  static const int lockTimeoutSeconds = 30;
  
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
    debugPrint('App lifecycle state changed: $state');
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _handleAppPaused();
        break;
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        break;
      case AppLifecycleState.hidden:
        // App is hidden but still running
        _handleAppPaused();
        break;
    }
    
    _lastLifecycleState = state;
  }
  
  void _handleAppPaused() {
    if (isAppLockEnabled.value && _authController.currentUser != null) {
      _backgroundTime = DateTime.now();
      debugPrint('App went to background at: $_backgroundTime');
    }
  }
  
  void _handleAppResumed() {
    if (isAppLockEnabled.value && 
        _authController.currentUser != null && 
        _backgroundTime != null) {
      
      final timeInBackground = DateTime.now().difference(_backgroundTime!);
      debugPrint('App resumed after: ${timeInBackground.inSeconds} seconds');
      
      if (timeInBackground.inSeconds >= lockTimeoutSeconds) {
        _lockApp();
      }
      
      _backgroundTime = null;
    }
  }
  
  void _lockApp() {
    debugPrint('Locking app');
    isAppLocked.value = true;
    
    // Navigate to lock screen
    Get.offAllNamed('/app-lock');
  }
  
  Future<void> unlockWithPin(String pin) async {
    if (pin == appPin.value) {
      _unlockApp();
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
           _authController.currentUser != null && 
           hasSetPin.value;
  }
}