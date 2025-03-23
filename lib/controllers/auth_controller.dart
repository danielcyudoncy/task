// controllers/auth_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:task/service/firebase_service.dart';
import 'dart:io';

class AuthController extends GetxController {
  static AuthController instance = Get.find<AuthController>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseService _firebaseService = FirebaseService();

  FirebaseAuth get auth => _auth;

  var isLoading = false.obs;
  var fullName = "".obs; // ✅ Store Full Name
  var selectedRole = ''.obs;

  final List<String> userRoles = [
    "Reporter",
    "Cameraman",
    "Assignment Editor",
    "Head of Department",
    "Admin"
  ];

  // ✅ Fetch user data from Firestore after login/signup
  Future<void> loadUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot? userData =
            await _firebaseService.getUserData(user.uid);
        if (userData != null && userData.exists) {
          fullName.value =
              userData["fullName"] ?? "User"; // ✅ Store fetched name
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load user data.");
    }
  }

  // ✅ Register New User (Includes Full Name)
  Future<void> signUp(
      String fullName, String email, String password, String role) async {
    try {
      isLoading(true);
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        String? fcmToken = await FirebaseMessaging.instance.getToken();

        await _firebaseService.saveUserData(user.uid, {
          "uid": user.uid,
          "fullName": fullName, // ✅ Store Full Name
          "email": email,
          "role": role,
          "profilePic": "",
          "fcmToken": fcmToken ?? "",
        });

        this.fullName.value = fullName; // ✅ Set Full Name
        Get.toNamed("/profile-update");
      }
    } catch (e) {
      Get.snackbar("Error", "Signup failed.");
    } finally {
      isLoading(false);
    }
  }

  // ✅ Upload Profile Picture
  Future<void> uploadProfilePicture(File imageFile) async {
    try {
      isLoading(true);
      print("🚀 Uploading profile picture...");

      String uid = _auth.currentUser!.uid;
      Reference ref = _storage.ref().child("profile_pics/$uid.jpg");

      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() {});

      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _firebaseService.updateUserData(uid, {"profilePic": downloadUrl});
      print("✅ Upload success: $downloadUrl");

      Get.snackbar("Success", "Profile picture updated successfully.");
    } catch (e) {
      print("❌ Upload failed: $e");
      Get.snackbar("Error", "Failed to upload image.");
    } finally {
      isLoading(false);
    }
  }

  // ✅ Save Firebase Cloud Messaging (FCM) Token
  Future<void> saveFCMToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null && _auth.currentUser != null) {
        await _firebaseService
            .updateUserData(_auth.currentUser!.uid, {"fcmToken": token});
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to save FCM Token.");
    }
  }

  // ✅ User Login (Loads Full Name)
  Future<void> login(String email, String password) async {
    try {
      isLoading(true);
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await loadUserData(); // ✅ Load Full Name after login
      await saveFCMToken(); // ✅ Ensure FCM Token is saved
      Get.offAllNamed("/home");
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", _handleAuthError(e));
    } finally {
      isLoading(false);
    }
  }

  // ✅ User Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      fullName.value = ""; // ✅ Clear Full Name
      Get.offAllNamed("/signup");
    } catch (e) {
      Get.snackbar("Error", "Logout failed.");
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
