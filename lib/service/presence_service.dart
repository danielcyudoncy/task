// service/presence_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';
import 'package:task/utils/constants/app_constants.dart';

class PresenceService extends GetxService {
  DatabaseReference? _presenceRef;
  DatabaseReference? _userStatusRef;
  final RxString _status = 'offline'.obs;
  String? _currentUserId;
  bool _isInitialized = false;

  String get status => _status.value;
  bool get isInitialized => _isInitialized;

  StreamSubscription? _connectionSubscription;

  @override
  Future<void> onInit() async {
    super.onInit();
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        if (_currentUserId != user.uid) {
          // User changed or logged in
          await _cleanup();
          await _initializePresence();
        }
      } else {
        // User logged out
        await _cleanup();
        _currentUserId = null;
        _isInitialized = false;
        _status.value = 'offline';
      }
    });
  }

  Future<void> _cleanup() async {
    await _connectionSubscription?.cancel();
    if (_isInitialized && _userStatusRef != null) {
      try {
        await _userStatusRef!.onDisconnect().cancel();
        await setOffline();
      } catch (e) {
        Get.log('PresenceService cleanup error: $e', isError: true);
      }
    }
  }

  Future<void> _initializePresence() async {
    try {
      Get.log('PresenceService: Starting initialization...');

      _currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_currentUserId == null) {
        Get.log('PresenceService: No authenticated user');
        return;
      }

      Get.log('PresenceService: Initializing database connection...');

      // Initialize with correct database URL
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: ExternalUrls.firebaseRtdbUrl,
      );

      _presenceRef = database.ref('.info/connected');
      _userStatusRef = database.ref('status/$_currentUserId');

      Get.log('PresenceService: Setting up connection listener...');
      _setupConnectionListener();

      _isInitialized = true;
      Get.log('PresenceService initialized for user $_currentUserId');
    } catch (e) {
      Get.log('PresenceService initialization failed: $e', isError: true);
      _isInitialized = false;
    }
  }

  void _setupConnectionListener() {
    if (_presenceRef == null) {
      Get.log(
          'PresenceService: _presenceRef is null, skipping connection listener');
      return;
    }

    _connectionSubscription = _presenceRef!.onValue.listen((event) async {
      final isConnected = event.snapshot.value as bool? ?? false;
      Get.log('PresenceService: Connection status changed: $isConnected');
      if (isConnected) {
        await _establishPresence();
      } else {
        _status.value = 'offline';
      }
    }, onError: (error) {
      Get.log('Connection listener error: $error', isError: true);
      _status.value = 'error';
    });
  }

  Future<void> _establishPresence() async {
    try {
      Get.log('PresenceService: Establishing presence...');
      await _setupDisconnectHandler();
      await setOnline();
    } catch (e) {
      Get.log('Failed to establish presence: $e', isError: true);
    }
  }

  Future<void> _setupDisconnectHandler() async {
    try {
      if (_userStatusRef == null) {
        Get.log(
            'PresenceService: _userStatusRef is null, skipping disconnect handler');
        return;
      }

      // Check if user is still authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Get.log(
            'PresenceService: User not authenticated, skipping disconnect handler');
        return;
      }

      await _userStatusRef!.onDisconnect().update({
        'status': 'offline',
        'lastSeen': ServerValue.timestamp,
      });
      Get.log('PresenceService: Disconnect handler set up successfully');
    } catch (e) {
      Get.log('Failed to setup disconnect handler: $e', isError: true);
      // Don't throw error for permission issues - just continue without disconnect handler
      if (!e.toString().contains('permission') &&
          !e.toString().contains('denied')) {
        // Only log non-permission errors as actual errors
        Get.log(
            'PresenceService: Non-permission error in disconnect handler: $e',
            isError: true);
      }
    }
  }

  Future<void> setOnline() async {
    if (!_isInitialized) {
      Get.log('PresenceService: Not initialized, skipping setOnline');
      return;
    }

    if (_userStatusRef == null || _currentUserId == null) {
      Get.log(
          'PresenceService: Required references are null, skipping setOnline');
      return;
    }

    // Check if user is still authenticated
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid != _currentUserId) {
      Get.log(
          'PresenceService: User not authenticated or UID mismatch, skipping setOnline');
      _status.value = 'offline';
      return;
    }

    try {
      Get.log('PresenceService: Setting user online...');
      await _userStatusRef!.update({
        'status': 'online',
        'lastSeen': ServerValue.timestamp,
        'userId': _currentUserId,
      });
      _status.value = 'online';
      Get.log('PresenceService: User set to online successfully');
    } catch (e) {
      Get.log('Failed to set online status: $e', isError: true);
      // Don't set status to error for permission issues - just stay offline
      if (e.toString().contains('permission') ||
          e.toString().contains('denied')) {
        Get.log('PresenceService: Permission denied, staying offline silently');
        _status.value = 'offline';
      } else {
        _status.value = 'error';
      }
    }
  }

  Future<void> setOffline() async {
    if (!_isInitialized) {
      Get.log('PresenceService: Not initialized, skipping setOffline');
      return;
    }

    if (_userStatusRef == null) {
      Get.log('PresenceService: _userStatusRef is null, skipping setOffline');
      return;
    }

    // Check if user is still authenticated
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Get.log('PresenceService: User not authenticated, skipping setOffline');
      _status.value = 'offline';
      return;
    }

    try {
      Get.log('PresenceService: Setting user offline...');
      await _userStatusRef!.update({
        'status': 'offline',
        'lastSeen': ServerValue.timestamp,
      });
      _status.value = 'offline';
      Get.log('PresenceService: User set to offline successfully');
    } catch (e) {
      Get.log('Failed to set offline status: $e', isError: true);
      // Don't set status to error for permission issues - just stay offline
      if (e.toString().contains('permission') ||
          e.toString().contains('denied')) {
        Get.log('PresenceService: Permission denied, staying offline silently');
        _status.value = 'offline';
      } else {
        _status.value = 'error';
      }
    }
  }

  @override
  Future<void> onClose() async {
    try {
      if (_isInitialized && _userStatusRef != null) {
        Get.log('PresenceService: Cleaning up...');
        await _userStatusRef!.onDisconnect().cancel();
        await setOffline();
      }
    } catch (e) {
      Get.log('PresenceService cleanup error: $e', isError: true);
    }
    super.onClose();
  }
}
