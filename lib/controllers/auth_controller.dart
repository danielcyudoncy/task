// controllers/auth_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AuthController extends GetxController {
  static AuthController instance = Get.find();

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseStorage storage = FirebaseStorage.instance;

  var isLoading = false.obs;
  var selectedRole = ''.obs;

  final List<String> userRoles = [
    "Reporter",
    "Cameraman",
    "Assignment Editor",
    "Head of Department",
    "Admin"
  ];

  Future<void> signUp(String email, String password, String role) async {
    try {
      isLoading(true);
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await firestore.collection("users").doc(userCredential.user!.uid).set({
        "uid": userCredential.user!.uid,
        "email": email,
        "role": role,
        "profilePic": "",
      });

      Get.toNamed("/profile-update");
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading(false);
    }
  }

  Future<void> uploadProfilePicture(File imageFile) async {
    try {
      String uid = auth.currentUser!.uid;
      Reference ref = storage.ref().child("profile_pics/$uid.jpg");
      await ref.putFile(imageFile);
      String downloadUrl = await ref.getDownloadURL();

      await firestore
          .collection("users")
          .doc(uid)
          .update({"profilePic": downloadUrl});
    } catch (e) {
      Get.snackbar("Error", "Failed to upload image");
    }
  }
  Future<void> saveFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null && auth.currentUser != null) {
      await firestore
          .collection("users")
          .doc(auth.currentUser!.uid)
          .update({"fcmToken": token});
    }
  }

  Future<void> login(String email, String password) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
      await saveFCMToken();
    } catch (e) {
      Get.snackbar("Error", "Login failed");
    }
  }
}
