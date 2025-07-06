// service/presence_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';

class PresenceService extends GetxService {
  DatabaseReference? _presenceRef;
  DatabaseReference? _userStatusRef;
  final RxString _status = 'offline'.obs;
  String? _currentUserId;
  bool _isInitialized = false;

  String get status => _status.value;
  bool get isInitialized => _isInitialized;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializePresence();
  }

  Future<void> _initializePresence() async {
    try {
      Get.log('PresenceService: Starting initialization...');
      
      // Wait for auth to be ready
      await FirebaseAuth.instance.authStateChanges().firstWhere((user) => true);

      _currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_currentUserId == null) {
        Get.log('PresenceService: No authenticated user');
        return;
      }

      Get.log('PresenceService: Initializing database connection...');
      
      // Initialize with correct database URL
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://task-e5a96-default-rtdb.firebaseio.com',
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
      // Don't rethrow - let the service continue without presence
    }
  }

  void _setupConnectionListener() {
    if (_presenceRef == null) {
      Get.log('PresenceService: _presenceRef is null, skipping connection listener');
      return;
    }
    
    _presenceRef!.onValue.listen((event) async {
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
        Get.log('PresenceService: _userStatusRef is null, skipping disconnect handler');
        return;
      }
      
      await _userStatusRef!.onDisconnect().update({
        'status': 'offline',
        'lastSeen': ServerValue.timestamp,
      });
      Get.log('PresenceService: Disconnect handler set up successfully');
    } catch (e) {
      Get.log('Failed to setup disconnect handler: $e', isError: true);
    }
  }

  Future<void> setOnline() async {
    if (!_isInitialized) {
      Get.log('PresenceService: Not initialized, skipping setOnline');
      return;
    }
    
    if (_userStatusRef == null || _currentUserId == null) {
      Get.log('PresenceService: Required references are null, skipping setOnline');
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
      _status.value = 'error';
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
      _status.value = 'error';
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
