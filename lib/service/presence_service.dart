// service/presence_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:get/get.dart';

class PresenceService extends GetxService {
  late DatabaseReference _presenceRef;
  late DatabaseReference _userStatusRef;
  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Future<void> onInit() async {
    super.onInit();
    if (currentUserId == null) return;

    _presenceRef = FirebaseDatabase.instance.ref('.info/connected');
    _userStatusRef = FirebaseDatabase.instance.ref('status/$currentUserId');

    _presenceRef.onValue.listen((event) async {
      final isConnected = event.snapshot.value as bool? ?? false;
      if (isConnected) {
        await _setupOnDisconnect();
        await _updateStatus('online');
      }
    });
  }

  Future<void> _setupOnDisconnect() async {
    try {
      await _userStatusRef.onDisconnect().update({
        'status': 'offline',
        'lastSeen': ServerValue.timestamp,
      });
    } catch (e) {
      Get.log('PresenceService: Failed to setup onDisconnect - $e');
    }
  }

  Future<void> _updateStatus(String status) async {
    try {
      await _userStatusRef.update({
        'status': status,
        'lastSeen': ServerValue.timestamp,
        'userId': currentUserId,
      });
    } catch (e) {
      Get.log('PresenceService: Failed to update status - $e');
    }
  }

  Future<void> setOnline() => _updateStatus('online');
  Future<void> setOffline() => _updateStatus('offline');

  @override
  Future<void> onClose() async {
    await _userStatusRef.onDisconnect().cancel();
    super.onClose();
  }
}
