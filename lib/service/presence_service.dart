// service/presence_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';

class PresenceService extends GetxService {
  DatabaseReference? _presenceRef;
  DatabaseReference? _userStatusRef;
  final RxString _status = 'offline'.obs;
  String? _currentUserId;
  bool _isInitialized = false;
  late FirebaseDatabase _database; // Instance variable

  String get status => _status.value;
  bool get isInitialized => _isInitialized;
  
  // Global online users count
  final RxInt onlineUsersCount = 0.obs;
  StreamSubscription? _onlineUsersSubscription;

  StreamSubscription? _connectionSubscription;

  @override
  Future<void> onInit() async {
    super.onInit();
    _initializeDatabase(); // Initialize database instance first
    
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

  void _initializeDatabase() {
    try {
      // Determine if we should use the emulator based on the environment flag
      const useEmulator =
          bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);

      if (useEmulator) {
        _database = FirebaseDatabase.instance;
        Get.log('PresenceService: Using Emulator Database instance');
      } else {
        // Use the default instance to ensure consistency with Firebase.initializeApp
        _database = FirebaseDatabase.instance;
        Get.log(
            'PresenceService: Using Default Database instance at ${_database.app.options.databaseURL}');
      }
      
      _startListeningToOnlineUsers();
    } catch (e) {
      Get.log('PresenceService: Database initialization failed: $e', isError: true);
    }
  }

  void _startListeningToOnlineUsers() {
    _onlineUsersSubscription?.cancel();
    
    try {
      final statusRef = _database.ref('status');
      _onlineUsersSubscription = statusRef.onValue.listen((event) {
        if (event.snapshot.value != null) {
          try {
            final data = event.snapshot.value;
            int count = 0;
            // Get current user ID directly from FirebaseAuth to ensure accuracy
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
            
            if (data is Map) {
              data.forEach((key, value) {
                // Check if user is online AND is not the current user
                if (key != currentUserId && value is Map && value['status'] == 'online') {
                  count++;
                }
              });
            }
            onlineUsersCount.value = count;
          } catch (e) {
            Get.log('PresenceService: Error parsing online users data: $e', isError: true);
          }
        } else {
          onlineUsersCount.value = 0;
        }
      }, onError: (error) {
         Get.log('PresenceService: Error listening to online users: $error', isError: true);
      });
    } catch (e) {
      Get.log('PresenceService: Failed to setup online users listener: $e', isError: true);
    }
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

      // Database is already initialized in _initializeDatabase
      
      _presenceRef = _database.ref('.info/connected');
      _userStatusRef = _database.ref('status/$_currentUserId');

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
        // Force an immediate update
        await setOnline();
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
      // Write to both status and lastSeen to ensure the node is created
      await _userStatusRef!.update({
        'status': 'online',
        'lastSeen': ServerValue.timestamp,
        'userId': _currentUserId,
        'email': currentUser.email, // Helpful for debugging
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
