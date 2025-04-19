// controllers/auth_controller.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:task/controllers/admin_controller.dart';
import 'package:task/service/firebase_service.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find<AuthController>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseService _firebaseService = FirebaseService();

  FirebaseAuth get auth => _auth;
  FirebaseService get firebaseService => _firebaseService;

  var isLoading = false.obs;
  var fullName = "".obs;
  var profilePic = "".obs;
  var selectedRole = ''.obs;
  var userRole = ''.obs;
  var isProfileComplete = false.obs;
  final lastActivity = DateTime.now().obs;

  final List<String> userRoles = [
    "Reporter",
    "Cameraman",
    "Assignment Editor",
    "Head of Department",
    "Admin"
  ];

  @override
  void onInit() {
    super.onInit();
    // Initialize only once
    if (!Get.isRegistered<AuthController>()) {
      _initializeUserSession();
    }
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        debugPrint("User signed out");
        Get.offAllNamed("/login");
      } else {
        debugPrint("User signed in: ${user.uid}");
      }
    });
  }

  @override
  void onReady() {
    ever(userRole, (_) => _handleRoleChange());
    debounce(lastActivity, (_) => _checkInactivity(),
        time: const Duration(minutes: 30));
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
        if (Get.currentRoute != "/login") {
          Get.offAllNamed("/login");
        }
      }
    } catch (e) {
      debugPrint("Session initialization error: $e");
      await logout();
      Get.offAllNamed("/login");
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
        fullName.value = userData['fullName']?.toString() ?? 'User';
        profilePic.value = userData['photoUrl']?.toString() ?? '';
        userRole.value = userData['role']?.toString() ?? '';
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
    debugPrint("Current role: ${userRole.value}");
    debugPrint("Current route: ${Get.currentRoute}");

    switch (userRole.value) {
      case "Admin":
      case "Assignment Editor":
      case "Head of Department":
        if (Get.currentRoute != "/admin-dashboard") {
          Get.offAllNamed("/admin-dashboard");
        }
        break;
      case "Reporter":
      case "Cameraman":
        if (Get.currentRoute != "/home") {
          Get.offAllNamed("/home");
        }
        break;
      default:
        Get.offAllNamed("/login");
        break;
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

  Future<void> uploadProfilePicture(File imageFile) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      Get.snackbar("Error", "User not logged in.");
      return;
    }

    try {
      isLoading.value = true;
      String filePath = "profile_pictures/${user.uid}.jpg";
      UploadTask uploadTask = _storage.ref(filePath).putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': downloadUrl,
      });

      profilePic.value = downloadUrl;
      Get.snackbar("Success", "Profile picture updated successfully.");
    } catch (e) {
      Get.snackbar(
          "Error", "Failed to upload profile picture. Please try again.");
    } finally {
      isLoading.value = false;
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

      // Ensure we have a user
      if (credential.user == null) throw Exception("No user returned");

      // Load user data before navigation
      await loadUserData();
      lastActivity.value = DateTime.now();

      // Check profile completion
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

  Future<void> logout() async {
    try {
      await _auth.signOut();
      resetUserData();
      Get.offAllNamed("/login");
    } catch (e) {
      Get.snackbar("Error", "Logout failed. Please try again.");
    }
  }

  void resetUserData() {
    fullName.value = "";
    profilePic.value = "";
    userRole.value = "";
    isProfileComplete.value = false;
  }

  void _checkInactivity() {
    if (DateTime.now().difference(lastActivity.value) >
        const Duration(minutes: 30)) {
      logout();
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return "Email is already in use.";
      case 'weak-password':
        return "Password should be at least 6 characters.";
      case 'user-not-found':
        return "No user found with this email.";
      case 'wrong-password':
        return "Incorrect password.";
      default:
        return "Authentication failed. Please try again.";
    }
  }
}
