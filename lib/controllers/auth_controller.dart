// controllers/auth_controller.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:task/service/firebase_service.dart';
import 'package:flutter/foundation.dart'; // ✅ For kIsWeb

class AuthController extends GetxController {
  static AuthController instance = Get.find<AuthController>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  FirebaseAuth get auth => _auth;

  var isLoading = false.obs;
  var fullName = "".obs;
  var profilePic = "".obs;
  var selectedRole = ''.obs;
  var userRole = ''.obs;

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
    loadUserData();
  }

  // ✅ Fetch user data from Firestore
  Future<void> loadUserData() async {
    try {
      print('Loading user data...');
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot? userData =
            await _firebaseService.getUserData(user.uid);
        if (userData != null && userData.exists) {
          fullName.value = userData["fullName"]?.toString() ?? "User";
          profilePic.value = userData["photoUrl"]?.toString() ?? "";
          userRole.value = userData["role"]?.toString() ?? "";
          print('User data loaded: ${userData.data()}');
        } else {
          Get.snackbar("Error", "User data not found.");
        }
      } else {
        Get.snackbar("Error", "No user is currently logged in.");
      }
    } catch (e) {
      print("Error loading user data: $e");
      Get.snackbar("Error", "Failed to load user data: $e");
    }
  }

  // ✅ Role-based Navigation
  void navigateBasedOnRole() {
    if (userRole.value == "Reporter" || userRole.value == "Cameraman") {
      Get.offAllNamed("/home");
    } else if (userRole.value == "Admin" ||
        userRole.value == "Assignment Editor" ||
        userRole.value == "Head of Department") {
      Get.offAllNamed("/admin-dashboard");
    } else {
      Get.offAllNamed("/login"); // ✅ Fallback if role is missing
    }
  }

  // ✅ Sign Up
  Future<void> signUp(
      String userFullName, String email, String password, String role) async {
    try {
      isLoading(true);
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        String? fcmToken;

        if (!kIsWeb) {
          fcmToken = await FirebaseMessaging.instance.getToken();
        }

        await _firebaseService.saveUserData(user.uid, {
          "uid": user.uid,
          "fullName": userFullName,
          "email": email,
          "role": role,
          "photoUrl": "", // ✅ Ensures default empty value
          "fcmToken": fcmToken ?? "",
        });

        fullName.value = userFullName;
        userRole.value = role;
        isLoading(false);

        Future.delayed(const Duration(milliseconds: 100), () {
          Get.offNamed("/profile-update");
        });
      } else {
        Get.snackbar("Error", "Failed to create user.");
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", _handleAuthError(e));
    } finally {
      isLoading(false);
    }
  }

  // ✅ Upload Profile Picture (Fixed Storage & Firestore Update)
  Future<void> uploadProfilePicture(File imageFile) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      Get.snackbar("Error", "User not logged in.");
      return;
    }

    try {
      print("Uploading profile picture...");
      isLoading.value = true;

      String filePath = "profile_pictures/${user.uid}.jpg";
      UploadTask uploadTask = _storage.ref(filePath).putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': downloadUrl,
      });

      profilePic.value = downloadUrl;
      print('Profile picture uploaded: $downloadUrl');
      Get.snackbar("Success", "Profile picture updated successfully.");
    } catch (e) {
      print("Error uploading profile picture: $e");
      Get.snackbar(
          "Error", "Failed to upload profile picture. Please try again.");
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ Save Firebase Cloud Messaging (FCM) Token
  Future<void> saveFCMToken() async {
    if (kIsWeb) {
      print("FCM Token not required on Web.");
      return;
    }

    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null && _auth.currentUser != null) {
        await _firebaseService
            .updateUserData(_auth.currentUser!.uid, {"fcmToken": token});
        print('FCM Token saved: $token');
      } else {
        print("FCM Token is null or user is not logged in.");
      }
    } catch (e) {
      print("Error saving FCM Token: $e");
      Get.snackbar("Error", "Failed to save FCM Token.");
    }
  }

  // ✅ Login User
  Future<void> login(String email, String password) async {
    try {
      isLoading(true);
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await loadUserData();
      await saveFCMToken();
      navigateBasedOnRole();
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", _handleAuthError(e));
    } finally {
      isLoading(false);
    }
  }

  // ✅ Logout User
  Future<void> logout() async {
    try {
      await _auth.signOut();
      fullName.value = "";
      userRole.value = "";
      profilePic.value = "";
      Get.offAllNamed("/login");
    } catch (e) {
      Get.snackbar("Error", "Logout failed.");
    }
  }

  // ✅ Delete User (Admin Only)
  Future<void> deleteUser(String userId) async {
    try {
      await _firebaseService.deleteUser(userId);
      Get.snackbar("Success", "User deleted successfully.");
    } catch (e) {
      Get.snackbar("Error", "Failed to delete user.");
    }
  }

  // ✅ Handle FirebaseAuth Errors
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
