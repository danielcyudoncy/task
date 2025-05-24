// controllers/auth_controller.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/admin_controller.dart';
import 'package:task/service/firebase_service.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find<AuthController>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseService _firebaseService = FirebaseService();

  Rx<User?> firebaseUser = Rx<User?>(null);
  RxMap<String, dynamic> userData = <String, dynamic>{}.obs;

  // Add this Rx<User?> and currentUser getter
  final Rx<User?> user = Rx<User?>(null);

  User? get currentUser => user.value;

  FirebaseAuth get auth => _auth;
  FirebaseService get firebaseService => _firebaseService;

  var isLoading = false.obs;
  var fullName = "".obs;
  var profilePic = "".obs;
  var selectedRole = ''.obs;
  var userRole = ''.obs;
  var isProfileComplete = false.obs;
  final lastActivity = DateTime.now().obs;

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final passwordController = TextEditingController();

  final List<String> userRoles = [
    "Reporter",
    "Cameraman",
    "Assignment Editor",
    "Head of Department",
    "Head of Unit",
    "Admin"
  ];

  @override
  void onInit() {
    super.onInit();
    _auth.authStateChanges().listen((User? userValue) {
      user.value = userValue; // keep user Rx in sync
      if (userValue == null) {
        debugPrint("User signed out");
      } else {
        debugPrint("User signed in: ${userValue.uid}");
      }
    });
  }

  @override
  void onReady() {
    firebaseUser.bindStream(_auth.authStateChanges());
    user.bindStream(_auth.authStateChanges()); // also bind user Rx to stream
    ever(userRole, (_) => _handleRoleChange());
    debounce(lastActivity, (_) => _checkInactivity(),
        time: const Duration(minutes: 30));
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  bool get canAssignTask {
    final role = userData['role'];
    return role == 'Admin' ||
        role == 'Assignment Editor' ||
        role == 'Head of Department' ||
        role == 'Head of Unit';
  }

  Future<void> _initializeUserSession() async {
    try {
      isLoading(true);
      if (_auth.currentUser != null) {
        await loadUserData();
        await saveFCMToken();
        if (userRole.value == "Admin") {
          await _verifyAdminPrivileges();
        }
        if (!isProfileComplete.value) {
          Get.offAllNamed("/profile-update");
        } else {
          navigateBasedOnRole();
        }
      } else {
        Get.offAllNamed("/login");
      }
    } catch (e) {
      debugPrint("Session initialization error: $e");
      await logout();
    } finally {
      isLoading(false);
    }
  }

  Future<void> initializeAuthSession() async {
    await _initializeUserSession();
  }

  Future<void> _verifyAdminPrivileges() async {
    try {
      final adminController = Get.find<AdminController>();
      await adminController.fetchAdminProfile();

      if (adminController.adminName.value.isEmpty) {
        throw Exception("Admin profile incomplete");
      }
    } catch (e) {
      debugPrint("Admin verification error: $e");
      await logout();
      rethrow;
    }
  }

  Future<void> loadUserData() async {
    try {
      if (_auth.currentUser == null) return;

      final userDoc = await _firestore
          .collection("users")
          .doc(_auth.currentUser!.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        fullName.value = userData['fullName'] ?? 'User';
        profilePic.value = userData['photoUrl'] ?? '';
        userRole.value = userData['role'] ?? '';
        isProfileComplete.value = userData['profileComplete'] ?? false;

        if (userRole.value.isEmpty) {
          throw Exception("User role not found");
        }
      } else {
        throw Exception("User document not found");
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
      resetUserData();
      rethrow;
    }
  }

  void resetUserData() {
    fullName.value = '';
    profilePic.value = '';
    userRole.value = '';
    isProfileComplete.value = false;
  }

  Future<void> completeProfile() async {
    try {
      if (_auth.currentUser == null) return;

      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        "profileComplete": true,
      });

      isProfileComplete.value = true;
      navigateBasedOnRole();
    } catch (e) {
      Get.snackbar("Error", "Failed to complete profile: ${e.toString()}");
      rethrow;
    }
  }

  void navigateBasedOnRole() {
    final route = Get.currentRoute;

    if (["Admin", "Assignment Editor", "Head of Department"]
        .contains(userRole.value)) {
      if (route != "/admin-dashboard") Get.offAllNamed("/admin-dashboard");
    } else if (["Reporter", "Cameraman"].contains(userRole.value)) {
      if (route != "/home") Get.offAllNamed("/home");
    } else {
      Get.offAllNamed("/login");
    }
  }

  void _handleRoleChange() {
    if (userRole.value.isEmpty) {
      Get.offAllNamed("/login");
      return;
    }

    final allowedAdminRoutes = [
      "Admin",
      "Assignment Editor",
      "Head of Department"
    ];
    final targetRoute = allowedAdminRoutes.contains(userRole.value)
        ? "/admin-dashboard"
        : "/home";

    if (Get.currentRoute != targetRoute) {
      Get.offAllNamed(targetRoute);
    }
  }

  Future<void> signUp(
      String userFullName, String email, String password, String role) async {
    try {
      isLoading(true);
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        String? fcmToken =
            !kIsWeb ? await FirebaseMessaging.instance.getToken() : null;

        await _firestore.collection('users').doc(user.uid).set({
          "uid": user.uid,
          "fullName": userFullName,
          "email": email,
          "role": role,
          "photoUrl": "",
          "fcmToken": fcmToken ?? "",
          "profileComplete": false,
          "createdAt": FieldValue.serverTimestamp(),
        });

        fullName.value = userFullName;
        userRole.value = role;
        Get.offNamed("/profile-update", arguments: {'role': role});
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", _handleAuthError(e));
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  Future<void> signUpAdmin(
      String userFullName, String email, String password) async {
    try {
      isLoading(true);
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        String? fcmToken =
            !kIsWeb ? await FirebaseMessaging.instance.getToken() : null;

        await _firestore.collection('users').doc(user.uid).set({
          "uid": user.uid,
          "fullName": userFullName,
          "email": email,
          "role": "Admin",
          "photoUrl": "",
          "fcmToken": fcmToken ?? "",
          "profileComplete": false,
          "createdAt": FieldValue.serverTimestamp(),
        });

        await _firestore.collection('admins').doc(user.uid).set({
          "uid": user.uid,
          "fullName": userFullName,
          "email": email,
          "createdAt": FieldValue.serverTimestamp(),
          "privileges": ["full_access"],
        });

        fullName.value = userFullName;
        userRole.value = "Admin";
        await Get.find<AdminController>().fetchAdminProfile();
        Get.offNamed("/profile-update", arguments: {'role': "Admin"});
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to create admin account: ${e.toString()}");
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  // auth_controller.dart
  Future<void> createAdminUser({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // 1. Create Firebase Auth user
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'uid': credential.user!.uid,
        'email': email,
        'fullName': fullName,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });

      Get.snackbar('Success', 'Admin user created');
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', e.message ?? 'Admin creation failed');
    }
  }

  Future<void> uploadProfilePicture(File imageFile) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      Get.snackbar("Error", "User not logged in.");
      return;
    }

    try {
      isLoading.value = true;

      if (!await imageFile.exists()) {
        throw Exception("Image file doesn't exist");
      }

      String filePath =
          "profile_pictures/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg";

      UploadTask uploadTask = _storage.ref(filePath).putFile(
            imageFile,
            SettableMetadata(contentType: 'image/jpeg'),
          );

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': downloadUrl,
      });

      profilePic.value = downloadUrl;
      Get.snackbar("Success", "Profile picture updated successfully.");
    } catch (e) {
      Get.snackbar("Upload Failed", "Error: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfileDetails() async {
    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'No user signed in');
      return;
    }

    try {
      isLoading(true);

      await _firebaseService.updateUserData(user.uid, {
        'fullName': fullNameController.text.trim(),
        'phoneNumber': phoneNumberController.text.trim(),
        'role': selectedRole.value,
        'profileComplete': true,
      });

      fullName.value = fullNameController.text.trim();
      userRole.value = selectedRole.value;
      isProfileComplete.value = true;

      Get.snackbar('Success', 'Profile updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  Future<void> saveFCMToken() async {
    if (kIsWeb) return;

    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null && _auth.currentUser != null) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({"fcmToken": token});
      }
    } catch (e) {
      debugPrint("Error saving FCM Token: $e");
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      isLoading(true);
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user == null) throw Exception("No user returned");

      await loadUserData();
      lastActivity.value = DateTime.now();

      if (!isProfileComplete.value) {
        Get.offAllNamed("/profile-update");
      } else {
        navigateBasedOnRole();
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", _handleAuthError(e));
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  Future<void> assignTask(String taskId, String userId) async {
    try {
      isLoading.value = true;
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'assignedTo': userId,
      });
      Get.snackbar("Success", "Task assigned successfully.");
    } catch (e) {
      Get.snackbar("Error", "Failed to assign task.");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      await _auth.signOut();
      resetUserData();
      Get.offAllNamed("/login");
    } catch (e) {
      Get.snackbar("Error", "Logout failed: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  // Sign out the current user
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    // Optionally: Clear your user Rx variable, navigate to login, etc.
    Get.offAllNamed('/onboarding');
  }

  // Delete the current user's account
  Future<void> deleteAccount() async {
    try {
      await FirebaseAuth.instance.currentUser?.delete();
      // Optionally: Clear user state, navigate to onboarding/login
      Get.offAllNamed('/onboarding');
    } catch (e) {
      Get.snackbar('Error', 'Could not delete account: $e');
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "No user found for that email.";
      case 'wrong-password':
        return "Wrong password provided.";
      case 'email-already-in-use':
        return "Email is already in use.";
      default:
        return e.message ?? "Authentication error.";
    }
  }

  void _checkInactivity() {
    final now = DateTime.now();
    if (now.difference(lastActivity.value).inMinutes >= 30) {
      logout();
    }
  }
}
