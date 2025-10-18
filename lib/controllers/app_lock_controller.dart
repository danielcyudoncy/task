// controllers/app_lock_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/service/biometric_service.dart';

class AppLockController extends GetxController with WidgetsBindingObserver {
  static AppLockController get to => Get.find<AppLockController>();
  final AuthController _authController = Get.find<AuthController>();
  final BiometricService _biometricService = Get.find<BiometricService>();

  // Observable variables
  final RxBool isAppLocked = false.obs;
  final RxBool isAppLockEnabled = true.obs;
  final RxBool isBiometricEnabled = false.obs; // Disabled by default
  final RxString appPin = ''.obs;
  final RxBool hasSetPin = false.obs;
  final RxBool isUsingDefaultPin = true.obs;
  final RxBool _isAuthenticating = false.obs;

  // Default PIN for first-time users
  static const String defaultPin = '0000';

  // App lifecycle state
  AppLifecycleState? _lastLifecycleState;
  DateTime? _backgroundTime;

  // Lock timeout (in seconds) - app locks after being minimized for this duration
  static const int lockTimeoutSeconds = 8;

  // Grace period after successful authentication (in seconds)
  static const int gracePeriodSeconds = 30;

  // Track last successful authentication time
  DateTime? _lastAuthTime;

  // Track last user activity time for preventing lock during active usage
  DateTime? _lastUserActivity;
  // Optional suspension window where locking is temporarily disabled
  DateTime? _suspendUntil;

  // Getter for current lifecycle state (useful for debugging and monitoring)
  AppLifecycleState? get currentLifecycleState => _lastLifecycleState;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();

    // Check if we should lock on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint(
          'AppLockController: Checking if app should be locked on startup...');
      if (shouldLockOnStartup()) {
        debugPrint('AppLockController: App should be locked on startup');
        // Delay navigation to ensure GetX is fully initialized
        Future.delayed(const Duration(milliseconds: 100), () {
          _lockApp();
        });
      } else {
        debugPrint('AppLockController: App should not be locked on startup');
      }
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint(
        'App lifecycle state changed from $_lastLifecycleState to $state');

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
    if (_isAuthenticating.value) {
      debugPrint(
          'AppLockController: Authentication in progress, ignoring pause.');
      return;
    }

    // If suspension is active, skip locking behavior while suspended
    if (_suspendUntil != null) {
      final now = DateTime.now();
      if (now.isBefore(_suspendUntil!)) {
        debugPrint(
            'AppLockController: Locking suspended until $_suspendUntil, skipping pause handling.');
        return;
      } else {
        // Suspension expired
        _suspendUntil = null;
      }
    }
    if (isAppLockEnabled.value && _authController.currentUser != null) {
      // Check if we're within the grace period after authentication
      if (_lastAuthTime != null) {
        final timeSinceAuth = DateTime.now().difference(_lastAuthTime!);
        if (timeSinceAuth.inSeconds < gracePeriodSeconds) {
          debugPrint(
              'AppLockController: Within grace period on pause (${gracePeriodSeconds - timeSinceAuth.inSeconds}s remaining), not locking');
          return;
        }
      }

      // Check if user has been active recently (within last 15 seconds)
      if (_lastUserActivity != null) {
        final timeSinceActivity = DateTime.now().difference(_lastUserActivity!);
        if (timeSinceActivity.inSeconds < 15) {
          debugPrint(
              'AppLockController: User was active recently (${15 - timeSinceActivity.inSeconds}s ago), not locking');
          return;
        }
      }

      _backgroundTime = DateTime.now();
      debugPrint(
          'App went to background (state: $currentState) at: $_backgroundTime');

      // Only lock if app was actually minimized (not just temporary UI changes)
      if (_lastLifecycleState == AppLifecycleState.resumed) {
        debugPrint('App is no longer in the foreground, will lock after timeout.');
        // Schedule lock after timeout instead of locking immediately
        Future.delayed(const Duration(seconds: lockTimeoutSeconds), () {
          // Double-check that app is still in background before locking
          if (_lastLifecycleState != AppLifecycleState.resumed &&
              isAppLockEnabled.value &&
              _authController.currentUser != null) {
            debugPrint('App still in background after timeout, locking.');
            _lockApp();
          } else {
            debugPrint('App is back in foreground or conditions changed, not locking.');
          }
        });
      }
    }
  }

  void _handleAppResumed() {
    debugPrint('AppLockController: App resumed from $_lastLifecycleState');
    debugPrint(
        'AppLockController: isAppLockEnabled = ${isAppLockEnabled.value}');
    debugPrint(
        'AppLockController: currentUser = ${_authController.currentUser != null}');

    // If suspension is active, clear it and avoid locking on resume
    if (_suspendUntil != null) {
      final now = DateTime.now();
      if (now.isBefore(_suspendUntil!)) {
        debugPrint(
            'AppLockController: Locking suspended until $_suspendUntil, skipping resume lock check.');
        _suspendUntil = null; // clear after resume
        return;
      } else {
        _suspendUntil = null;
      }
    }
    // Check if we should lock on resume
    if (isAppLockEnabled.value && _authController.currentUser != null) {
      // Check if we're within the grace period after authentication
      if (_lastAuthTime != null) {
        final timeSinceAuth = DateTime.now().difference(_lastAuthTime!);
        if (timeSinceAuth.inSeconds < gracePeriodSeconds) {
          debugPrint(
              'AppLockController: Within grace period (${gracePeriodSeconds - timeSinceAuth.inSeconds}s remaining), not locking');
          return;
        }
      }

      debugPrint('AppLockController: Conditions met for locking on resume');
      _lockApp();
    } else {
      debugPrint('AppLockController: App lock conditions not met on resume');
      debugPrint(
          'AppLockController: isAppLockEnabled = ${isAppLockEnabled.value}');
      debugPrint(
          'AppLockController: hasCurrentUser = ${_authController.currentUser != null}');
    }

    _backgroundTime = null;
  }

  /// Temporarily suspend app locking for the given duration.
  /// Use this when launching external UI flows (image picker, file picker)
  /// that cause the app to go to background and then return.
  void suspendLockFor(Duration duration) {
    _suspendUntil = DateTime.now().add(duration);
    debugPrint('AppLockController: Locking suspended until $_suspendUntil');
  }

  /// Clear any active lock suspension immediately.
  void clearLockSuspension() {
    _suspendUntil = null;
    debugPrint('AppLockController: Lock suspension cleared');
  }

  void _handleAppDetached() {
    debugPrint('App is being terminated - performing cleanup');

    // Clear sensitive data when app is being terminated
    _backgroundTime = null;
    _lastUserActivity = null;

    // If app lock is enabled, ensure the app will be locked on next startup
    if (isAppLockEnabled.value && _authController.currentUser != null) {
      debugPrint(
          'App terminated while locked - will require unlock on restart');
    }
  }

  void _lockApp() {
    debugPrint('Locking app - current route: ${Get.currentRoute}');
    debugPrint('App lock enabled: ${isAppLockEnabled.value}');
    debugPrint('Biometric enabled: ${isBiometricEnabled.value}');
    isAppLocked.value = true;

    // Navigate to app lock screen
    debugPrint('Navigating to app lock screen...');
    Get.offAllNamed('/app-lock');
    debugPrint('Navigation to app lock screen completed');
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

  // Biometric authentication removed

  /// Unlock app using biometric authentication
  Future<void> unlockWithBiometric() async {
    if (_isAuthenticating.value) {
      debugPrint('AppLockController: Authentication already in progress.');
      return;
    }
    try {
      _isAuthenticating.value = true;
      debugPrint('AppLockController: Attempting biometric unlock');

      // Check if biometric is enabled
      if (!isBiometricEnabled.value) {
        debugPrint('AppLockController: Biometric authentication is disabled');
        Get.snackbar(
          'Biometric Disabled',
          'Biometric authentication is disabled. Please enable it in settings or use PIN.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      // Attempt biometric authentication
      final authenticated = await _biometricService.authenticate(
        reason: 'Please authenticate to unlock the app',
        biometricOnly: false, // Allow fallback to device PIN if needed
      );

      if (authenticated) {
        debugPrint('AppLockController: Biometric authentication successful');
        _unlockApp();
      } else {
        debugPrint('AppLockController: Biometric authentication failed');
        // Error handling is done in BiometricService
      }
    } catch (e) {
      debugPrint('AppLockController: Error during biometric unlock: $e');
      Get.snackbar(
        'Authentication Error',
        'An error occurred during biometric authentication. Please try again or use PIN.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isAuthenticating.value = false;
    }
  }

  /// Check if biometric authentication is available and enabled
  bool get canUseBiometric {
    final biometricAvailable = _biometricService.isBiometricAvailable.value;
    final biometricEnabled = isBiometricEnabled.value;

    debugPrint('AppLockController: canUseBiometric check:');
    debugPrint('  - biometricAvailable: $biometricAvailable');
    debugPrint('  - biometricEnabled: $biometricEnabled');
    debugPrint('  - result: ${biometricEnabled && biometricAvailable}');

    return biometricEnabled && biometricAvailable;
  }

  /// Get biometric icon for UI display
  IconData get biometricIcon => _biometricService.getBiometricIcon();

  /// Get biometric type string for UI display
  String get biometricTypeString => _biometricService.getBiometricTypeString();

  void _unlockApp() async {
    debugPrint('Unlocking app');
    isAppLocked.value = false;
    _lastAuthTime = DateTime.now();
    _lastUserActivity = DateTime.now(); // Reset activity timer on unlock

    // Navigate back to appropriate screen based on user role
    await _authController.navigateBasedOnRole();
  }

  /// Track user activity to prevent locking during active usage
  void trackUserActivity() {
    _lastUserActivity = DateTime.now();
    debugPrint('AppLockController: User activity tracked at: $_lastUserActivity');
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
      isBiometricEnabled.value =
          prefs.getBool('biometric_enabled') ?? true; // Enable by default
      appPin.value = prefs.getString('app_pin') ?? '';
      hasSetPin.value = appPin.value.isNotEmpty;
      isUsingDefaultPin.value = prefs.getBool('is_using_default_pin') ?? true;

      debugPrint('AppLockController: Settings loaded:');
      debugPrint('  - isAppLockEnabled: ${isAppLockEnabled.value}');
      debugPrint('  - isBiometricEnabled: ${isBiometricEnabled.value}');
      debugPrint('  - hasSetPin: ${hasSetPin.value}');
      debugPrint('  - isUsingDefaultPin: ${isUsingDefaultPin.value}');
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
    return isAppLockEnabled.value && _authController.currentUser != null;
  }
}
