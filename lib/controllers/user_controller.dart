// controllers/user_controller.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task/models/chat_model.dart';
import 'package:task/service/user_deletion_service.dart';
import '../controllers/auth_controller.dart';


class UserController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthController authController = Get.find<AuthController>();
  final UserDeletionService userDeletionService;
  

  // Existing observables
  var reporters = <Map<String, dynamic>>[].obs;
  var cameramen = <Map<String, dynamic>>[].obs;
  var allUsers = <Map<String, dynamic>>[].obs;
  var isDeleting = false.obs;

  // New chat-related observables
  final RxList<ChatUser> _availableChatUsers = <ChatUser>[].obs;
  List<ChatUser> get availableChatUsers => _availableChatUsers
      .where((user) => user.uid != authController.currentUser!.uid)
      .toList();

  UserController(this.userDeletionService);

  @override
  void onInit() {
    super.onInit();
    fetchReporters();
    fetchCameramen();
    fetchAllUsers();
    _initChatUsers();
  }

  @override
  void onClose() {
    super.onClose();
    reporters.close();
    cameramen.close();
    allUsers.close();
  }

  // ----------------------------
  // EXISTING METHODS (UNCHANGED)
  // ----------------------------
  void fetchReporters() {
    reporters.bindStream(
      _firestore
          .collection("users")
          .where("role", isEqualTo: "Reporter")
          .snapshots()
          .handleError((error) => Get.log("Reporter fetch error: $error"))
          .map((snapshot) => snapshot.docs.map(_mapUser).toList()),
    );
  }

  void fetchCameramen() {
    cameramen.bindStream(
      _firestore
          .collection("users")
          .where("role", isEqualTo: "Cameraman")
          .snapshots()
          .handleError((error) => Get.log("Cameraman fetch error: $error"))
          .map((snapshot) => snapshot.docs.map(_mapUser).toList()),
    );
  }

  void fetchAllUsers() {
    if (_isAdminOrEditor(authController.userRole.value)) {
      allUsers.bindStream(
        _firestore
            .collection("users")
            .snapshots()
            .handleError((error) => Get.log("All users fetch error: $error"))
            .map((snapshot) => snapshot.docs
                .where((doc) => doc.id != authController.currentUser!.uid)
                .map(_mapUserWithRole)
                .toList()),
      );
    }
  }

  Map<String, dynamic> _mapUser(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return {
      "id": doc.id,
      "name": data["fullName"] ?? "Unknown",
    };
  }

  Map<String, dynamic> _mapUserWithRole(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return {
      "id": doc.id,
      "name": data["fullName"] ?? "Unknown",
      "role": data["role"] ?? "Unknown",
    };
  }

  bool _isAdminOrEditor(String role) {
    const validRoles = ["Admin", "Assignment Editor", "Head of Department"];
    return validRoles.contains(role);
  }

  Future<void> deleteUser(String uid) async {
    isDeleting.value = true;
    try {
      await userDeletionService.deleteUserByAdmin(uid);
      allUsers.removeWhere((user) => user["id"] == uid);
      Get.snackbar("Success", "User deleted!");
    } catch (e) {
      Get.snackbar("Error", "Failed to delete user: $e");
    } finally {
      isDeleting.value = false;
    }
  }

  // ----------------------------
  // NEW CHAT-RELATED METHODS
  // ----------------------------
  void _initChatUsers() {
    _firestore.collection('users').snapshots().listen((snapshot) {
      _availableChatUsers.value =
          snapshot.docs.map((doc) => ChatUser.fromFirestore(doc)).toList();
    }, onError: (error) => Get.log("Chat users error: $error"));
  }

  List<ChatUser> searchChatUsers(String query) {
    return availableChatUsers
        .where((user) => user.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  ChatUser? getChatUser(String uid) {
    return _availableChatUsers.firstWhereOrNull((user) => user.uid == uid);
  }

  Future<void> updateFcmToken(String token) async {
    try {
      await _firestore
          .collection('users')
          .doc(authController.currentUser!.uid)
          .update({
        'fcmToken': token,
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Get.log('FCM token update failed: $e', isError: true);
    }
  }

  Future<void> updateUserPresence(bool isOnline) async {
    try {
      await _firestore
          .collection('users')
          .doc(authController.currentUser!.uid)
          .update({
        'isOnline': isOnline,
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Get.log('Presence update failed: $e', isError: true);
    }
  }
}
