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

  String get status => _status.value;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializePresence();
  }

  Future<void> _initializePresence() async {
    try {
      // Wait for auth to be ready
      await FirebaseAuth.instance.authStateChanges().firstWhere((user) => true);

      _currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_currentUserId == null) {
        Get.log('PresenceService: No authenticated user');
        return;
      }

      // Initialize with explicit database URL
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL:
            'https://task-e5a96.firebaseio.com', // Replace with your actual URL
      );

      _presenceRef = database.ref('.info/connected');
      _userStatusRef = database.ref('status/$_currentUserId');

      _setupConnectionListener();
      Get.log('PresenceService initialized for user $_currentUserId');
    } catch (e) {
      Get.log('PresenceService initialization failed: $e', isError: true);
      rethrow;
    }
  }

  void _setupConnectionListener() {
    _presenceRef?.onValue.listen((event) async {
      final isConnected = event.snapshot.value as bool? ?? false;
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
      await _setupDisconnectHandler();
      await setOnline();
    } catch (e) {
      Get.log('Failed to establish presence: $e', isError: true);
    }
  }

  Future<void> _setupDisconnectHandler() async {
    try {
      await _userStatusRef?.onDisconnect().update({
        'status': 'offline',
        'lastSeen': ServerValue.timestamp,
      });
    } catch (e) {
      Get.log('Failed to setup disconnect handler: $e', isError: true);
    }
  }

  Future<void> setOnline() async {
    if (_userStatusRef == null || _currentUserId == null) return;

    try {
      await _userStatusRef!.update({
        'status': 'online',
        'lastSeen': ServerValue.timestamp,
        'userId': _currentUserId,
      });
      _status.value = 'online';
    } catch (e) {
      Get.log('Failed to set online status: $e', isError: true);
      _status.value = 'error';
    }
  }

  Future<void> setOffline() async {
    if (_userStatusRef == null) return;

    try {
      await _userStatusRef!.update({
        'status': 'offline',
        'lastSeen': ServerValue.timestamp,
      });
      _status.value = 'offline';
    } catch (e) {
      Get.log('Failed to set offline status: $e', isError: true);
      _status.value = 'error';
    }
  }

  @override
  Future<void> onClose() async {
    try {
      await _userStatusRef?.onDisconnect().cancel();
      await setOffline();
    } catch (e) {
      Get.log('PresenceService cleanup error: $e', isError: true);
    }
    super.onClose();
  }
}
