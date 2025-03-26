import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:task/service/firebase_service.dart';
import 'package:flutter/foundation.dart'; // ✅ Import for kIsWeb
import 'dart:io';

class AuthController extends GetxController {
  static AuthController instance = Get.find<AuthController>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
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

  // ✅ Fetch user data from Firestore
  Future<void> loadUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot? userData = await _firebaseService.getUserData(user.uid);
        if (userData != null && userData.exists) {
          fullName.value = userData["fullName"] ?? "User";
          profilePic.value = userData["profilePic"] ?? "";
          userRole.value = userData["role"] ?? "";
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load user data.");
    }
  }

  // ✅ Role-based Navigation (Fixed)
  void navigateBasedOnRole() {
    if (userRole.value == "Reporter" || userRole.value == "Cameraman") {
      Get.offAllNamed("/home");
    } else if (userRole.value == "Admin" || userRole.value == "Assignment Editor" || userRole.value == "Head of Department") {
      Get.offAllNamed("/admin-dashboard");
    } else {
      Get.offAllNamed("/login"); // ✅ Fallback if role is missing
    }
  }

  // ✅ Sign Up (Fixed)
  Future<void> signUp(String userFullName, String email, String password, String role) async {
    try {
      isLoading(true);
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;
      if (user != null) {
        String? fcmToken;

        if (!kIsWeb) { // ✅ Prevents Web Crashes
          fcmToken = await FirebaseMessaging.instance.getToken();
        }

        await _firebaseService.saveUserData(user.uid, {
          "uid": user.uid,
          "fullName": userFullName,
          "email": email,
          "role": role,
          "profilePic": "",
          "fcmToken": fcmToken ?? "",
        });

        fullName.value = userFullName;
        userRole.value = role;
        isLoading(false);

        // ✅ Delay navigation to ensure UI updates properly
        Future.delayed(const Duration(milliseconds: 100), () {
          Get.offNamed("/profile-update");
        });
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", _handleAuthError(e));
    } finally {
      isLoading(false);
    }
  }

  // ✅ Upload Profile Picture
  Future<void> uploadProfilePicture(File imageFile) async {
    try {
      isLoading(true);
      String uid = _auth.currentUser!.uid;
      Reference ref = _storage.ref().child("profile_pics/$uid.jpg");
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _auth.currentUser?.updatePhotoURL(downloadUrl);
      await _firebaseService.updateUserData(uid, {"profilePic": downloadUrl});

      profilePic.value = downloadUrl;
      Get.snackbar("Success", "Profile picture updated successfully.");
    } catch (e) {
      Get.snackbar("Error", "Failed to upload image.");
    } finally {
      isLoading(false);
    }
  }

  // ✅ Save Firebase Cloud Messaging (FCM) Token (Fixed for Web)
  Future<void> saveFCMToken() async {
    if (kIsWeb) {
      print("🔥 FCM Token not required on Web.");
      return; // ✅ Skip FCM on Web
    }

    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null && _auth.currentUser != null) {
        await _firebaseService.updateUserData(_auth.currentUser!.uid, {"fcmToken": token});
      }
    } catch (e) {
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
        return "An error occurred. Please try again.";
    }
  }
}
