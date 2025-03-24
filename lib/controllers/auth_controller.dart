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
  var profilePic = "".obs;
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
          fullName.value = userData["fullName"] ?? "User";
          profilePic.value =
              userData["profilePic"] ?? ""; // Load profile pic URL
        }
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load user data.");
    }
  }

  // ✅ Register New User (Includes Full Name)
 Future<void> signUp(
      String userFullName, String email, String password, String role) async {
    try {
      isLoading(true);
      print("🚀 Starting Sign Up...");

      // We'll catch the "email-already-in-use" error instead of using the deprecated method
      print("📧 Creating user with email: $email");

      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        print("✅ Firebase Auth Success! User ID: ${user.uid}");

        String? fcmToken = await FirebaseMessaging.instance.getToken();
        print("📂 Saving user data in Firestore...");

        await _firebaseService.saveUserData(user.uid, {
          "uid": user.uid,
          "fullName": userFullName, // Use the parameter name
          "email": email,
          "role": role,
          "profilePic": "",
          "fcmToken": fcmToken ?? "",
        });

        print("✅ Firestore Save Success! Navigating to Profile Update...");

        // Set the fullName observable
        fullName.value = userFullName;

        // Ensure we're not in a loading state
        isLoading(false);

        // Navigate with a slight delay to ensure UI updates
        Future.delayed(const Duration(milliseconds: 100), () {
          Get.offNamed("/profile-update");
        });
      }
    } on FirebaseAuthException catch (e) {
      print("❌ Firebase Auth Error: ${e.code}");

      // Handle specific Firebase Auth errors
      if (e.code == 'email-already-in-use') {
        Get.snackbar("Error", "Email is already in use.");
      } else if (e.code == 'weak-password') {
        Get.snackbar("Error", "Password is too weak.");
      } else {
        Get.snackbar("Error", "Signup failed: ${e.message}");
      }

      isLoading(false);
    } catch (e) {
      print("❌ Error during signup: $e");
      Get.snackbar("Error", "Signup failed: ${e.toString()}");
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

      // Update Firebase Auth user profile
      await _auth.currentUser?.updatePhotoURL(downloadUrl);

      // Update Firestore
      await _firebaseService.updateUserData(uid, {"profilePic": downloadUrl});

      // Update the observable
      profilePic.value = downloadUrl;

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
