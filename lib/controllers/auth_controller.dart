// controllers/auth_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AuthController extends GetxController {
  static AuthController instance = Get.find<AuthController>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
   FirebaseAuth get auth => _auth;

  var isLoading = false.obs;
  var selectedRole = ''.obs;

  final List<String> userRoles = [
    "Reporter",
    "Cameraman",
    "Assignment Editor",
    "Head of Department",
    "Admin"
  ];

  // Register New User
  Future<void> signUp(String email, String password, String role) async {
    try {
      isLoading(true);
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection("users").doc(user.uid).set({
          "uid": user.uid,
          "email": email,
          "role": role,
          "profilePic": "",
          "fcmToken": await FirebaseMessaging.instance.getToken(),
        });

        Get.toNamed("/profile-update");
      }
    } on FirebaseAuthException catch (e) {
      String message = "An error occurred";
      if (e.code == 'email-already-in-use') {
        message = "Email is already in use.";
      } else if (e.code == 'weak-password') {
        message = "Password should be at least 6 characters.";
      }
      Get.snackbar("Error", message);
    } catch (e) {
      Get.snackbar("Error", "Registration failed: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  // Upload Profile Picture
  Future<void> uploadProfilePicture(File imageFile) async {
    try {
      isLoading(true);
      String uid = _auth.currentUser!.uid;
      Reference ref = _storage.ref().child("profile_pics/$uid.jpg");
      await ref.putFile(imageFile);
      String downloadUrl = await ref.getDownloadURL();

      await _firestore.collection("users").doc(uid).update({"profilePic": downloadUrl});
      Get.snackbar("Success", "Profile picture updated successfully.");
    } catch (e) {
      Get.snackbar("Error", "Failed to upload image: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  // Save Firebase Cloud Messaging (FCM) Token
  Future<void> saveFCMToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null && _auth.currentUser != null) {
        await _firestore.collection("users").doc(_auth.currentUser!.uid).update({"fcmToken": token});
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to save FCM Token: ${e.toString()}");
    }
  }

  // User Login
  Future<void> login(String email, String password) async {
    try {
      isLoading(true);
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await saveFCMToken();
      Get.offAllNamed("/home");
    } on FirebaseAuthException catch (e) {
      String message = "Login failed";
      if (e.code == 'user-not-found') {
        message = "No user found with this email.";
      } else if (e.code == 'wrong-password') {
        message = "Incorrect password.";
      }
      Get.snackbar("Error", message);
    } catch (e) {
      Get.snackbar("Error", "Login failed: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  // User Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      Get.offAllNamed("/signup");
    } catch (e) {
      Get.snackbar("Error", "Logout failed: ${e.toString()}");
    }
  }
}
