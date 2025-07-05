// controllers/auth_controller.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/admin_controller.dart';
import 'package:task/service/firebase_service.dart';
import 'package:task/service/presence_service.dart';
import 'package:task/service/supabase_storage_service.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find<AuthController>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseService _firebaseService = FirebaseService();
  final SupabaseStorageService storageService = SupabaseStorageService();

  Rx<User?> firebaseUser = Rx<User?>(null);
  RxMap<String, dynamic> userData = <String, dynamic>{}.obs;

  final Rx<User?> user = Rx<User?>(null);
  RxBool isLoginPasswordHidden = true.obs;
  RxBool isSignUpPasswordHidden = true.obs;
  RxBool isConfirmPasswordHidden = true.obs;
 



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
  bool get isLoggedIn => currentUser != null;
  bool _isNavigating = false;
  bool _isInBuildPhase = false;

  @override
  void onInit() {
    super.onInit();
    debugPrint("AuthController: onInit called");
    // Ensure loading state is false on initialization
    isLoading(false);
    
    _auth.authStateChanges().listen((User? userValue) {
      user.value = userValue;
      if (userValue == null) {
        debugPrint("User signed out");
        _handlePresence(false); // Set offline when user logs out
      } else {
        debugPrint("User signed in: ${userValue.uid}");
        _handlePresence(true); // Set online when user logs in
      }
    });
  }

  @override
  void onReady() {
    firebaseUser.bindStream(_auth.authStateChanges());
    user.bindStream(_auth.authStateChanges());
    // Temporarily disable automatic role-based navigation to prevent build phase issues
    // debounce(userRole, (_) => _handleRoleChange(), time: const Duration(milliseconds: 100));
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

  void goToHome() {
    final role = userRole.value;
    if (role == "Admin" ||
        role == "Assignment Editor" ||
        role == "Head of Department") {
      Get.offAllNamed('/admin-dashboard');
    } else if (role == "Reporter" || role == "Cameraman") {
      Get.offAllNamed('/home');
    } else {
      Get.offAllNamed('/login');
    }
  }

  Future<void> _handlePresence(bool isOnline) async {
    if (Get.isRegistered<PresenceService>()) {
      final presence = Get.find<PresenceService>();
      if (isOnline) {
        await presence.setOnline();
      } else {
        await presence.setOffline();
      }
    }
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigateBasedOnRole();
          });
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

  // Add retry logic in loadUserData()
  Future<void> loadUserData() async {
    debugPrint("AuthController: Starting loadUserData");
    const maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        debugPrint("AuthController: loadUserData attempt ${attempt + 1}");
        if (_auth.currentUser == null) {
          debugPrint("AuthController: No current user, returning");
          return;
        }

        debugPrint("AuthController: Fetching user document for ${_auth.currentUser!.uid}");
        final userDoc = await _firestore
            .collection("users")
            .doc(_auth.currentUser!.uid)
            .get();

        if (userDoc.exists) {
          debugPrint("AuthController: User document exists, loading data");
          final data = userDoc.data()!;
          fullName.value = data['fullName'] ?? '';
          profilePic.value = data['photoUrl'] ?? '';
          userRole.value = data['role'] ?? '';
          isProfileComplete.value = data['profileComplete'] ?? false;

          userData.assignAll(data);
          debugPrint("AuthController: User data loaded successfully");
          return; // Success
        } else {
          debugPrint("AuthController: User document does not exist for ${_auth.currentUser!.uid}");
          resetUserData();
          throw Exception("User document not found");
        }
      } catch (e) {
        debugPrint("AuthController: loadUserData error on attempt ${attempt + 1}: $e");
        attempt++;
        if (attempt == maxRetries) {
          debugPrint("AuthController: loadUserData failed after $maxRetries attempts, resetting user data");
          resetUserData();
          rethrow;
        }
        debugPrint("AuthController: Retrying loadUserData in 1 second");
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  void resetUserData() {
    fullName.value = '';
    profilePic.value = '';
    userRole.value = '';
    isProfileComplete.value = false;
    userData.clear();
  }

  // In AuthController, modify completeProfile()
  Future<void> completeProfile() async {
    try {
      if (_auth.currentUser == null) return;

      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        "profileComplete": true,
        "fullName": fullName.value,
        "phoneNumber": phoneNumberController.text.trim(),
        "role": selectedRole.value,
      });

      // Force refresh user data
      await loadUserData();

      // Navigate based on role only after confirming update
      if (isProfileComplete.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigateBasedOnRole();
        });
      } else {
        Get.snackbar("Error", "Profile completion failed");
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to complete profile: ${e.toString()}");
      rethrow;
    }
  }

  // In AuthController, modify navigateBasedOnRole and _handleRoleChange
  // In AuthController
  void navigateBasedOnRole() {
    if (_isNavigating || _isInBuildPhase) {
      debugPrint("Skipping navigation - already navigating or in build phase");
      return;
    }
    
    _isNavigating = true;

    final role = userRole.value;
    debugPrint("Navigating based on role: $role");

    try {
      if (["Admin", "Assignment Editor", "Head of Department"].contains(role)) {
        Get.offAllNamed("/admin-dashboard");
      } else if (["Reporter", "Cameraman"].contains(role)) {
        Get.offAllNamed("/home");
      } else {
        Get.offAllNamed("/login");
      }
    } catch (e) {
      debugPrint("Navigation error: $e");
    } finally {
      _isNavigating = false;
    }
  }

  void _handleRoleChange() {
    // Temporarily disabled to prevent build phase issues
    // This will be re-enabled once we have a safer navigation mechanism
    debugPrint("Role change detected but navigation disabled for safety");
  }

  void setBuildPhase(bool inBuildPhase) {
    _isInBuildPhase = inBuildPhase;
  }

  void resetLoadingState() {
    debugPrint("AuthController: Resetting loading state");
    isLoading(false);
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

  Future<void> createAdminUser({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
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

  /// Profile picture upload (USES SUPABASE STORAGE, not Firebase Storage)
  Future<void> uploadProfilePicture(File imageFile) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      Get.snackbar("Error", "User not logged in.");
      return;
    }

    const String bucket = 'photos'; // use your actual Supabase bucket name

    try {
      isLoading.value = true;

      if (!await imageFile.exists()) {
        throw Exception("Image file doesn't exist");
      }

      // Delete old image from Supabase, if any
      String oldPhotoUrl = profilePic.value;
      String newFilePath =
          "profile_pictures/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg";

      // Only attempt to delete if photoUrl is a Supabase URL and is not empty
      if (oldPhotoUrl.isNotEmpty && oldPhotoUrl.contains("supabase")) {
        try {
          Uri uri = Uri.parse(oldPhotoUrl);
          // Supabase URL: .../storage/v1/object/public/photos/profile_pictures/xxxx.jpg
          // pathSegments: [storage, v1, object, public, photos, profile_pictures, ...]
          int bucketIndex = uri.pathSegments.indexOf(bucket);
          if (bucketIndex > -1 && uri.pathSegments.length > bucketIndex + 1) {
            String path = uri.pathSegments.sublist(bucketIndex + 1).join('/');
            if (path.isNotEmpty) {
              await storageService.deleteFile(bucket: bucket, path: path);
            }
          }
        } catch (e) {
          debugPrint("Failed to delete old Supabase image: $e");
        }
      }

      // Upload to Supabase Storage
      final result = await storageService.uploadFile(
        bucket: bucket,
        path: newFilePath,
        file: imageFile,
      );

      if (result != null) {
        final url = storageService.getPublicUrl(
          bucket: bucket,
          path: newFilePath,
        );

        // Save the Supabase URL in Firebase Firestore user profile
        await _firestore.collection('users').doc(user.uid).update({
          'photoUrl': url,
        });

        profilePic.value = url;
        Get.snackbar("Success", "Profile picture updated successfully.");
      } else {
        Get.snackbar("Upload Failed", "Could not upload the image.");
      }
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
      debugPrint("AuthController: Starting sign in process");
      isLoading(true);
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user == null) throw Exception("No user returned");

      debugPrint("AuthController: User signed in successfully, loading user data");
      await loadUserData();
      lastActivity.value = DateTime.now();
      await _handlePresence(true); // Set presence after successful login

      debugPrint("AuthController: User data loaded, profile complete: ${isProfileComplete.value}");
      if (!isProfileComplete.value) {
        debugPrint("AuthController: Navigating to profile update");
        Get.offAllNamed("/profile-update");
      } else {
        debugPrint("AuthController: Navigating based on role");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigateBasedOnRole();
        });
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("AuthController: Firebase auth error: ${e.message}");
      Get.snackbar("Error", _handleAuthError(e));
      rethrow;
    } catch (e) {
      debugPrint("AuthController: General error during sign in: $e");
      Get.snackbar("Error", "Sign in failed: $e");
      rethrow;
    } finally {
      debugPrint("AuthController: Setting isLoading to false");
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

      // 1. First reset local state immediately
      resetUserData();

      // 2. Then handle presence and auth signout
      await Future.wait([
        _handlePresence(false),
        _auth.signOut(),
      ]);

      // 3. Ensure complete cleanup before navigation
      await Future.delayed(const Duration(milliseconds: 100));

      // 4. Navigate with complete context reset
      Get.offAllNamed("/login", arguments: {'fromLogout': true});
    } catch (e) {
      Get.snackbar("Error", "Logout failed: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    Get.offAllNamed('/onboarding');
  }

  Future<void> deleteAccount() async {
    try {
      await FirebaseAuth.instance.currentUser?.delete();
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

  Future<void> forgotPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      Get.snackbar("Success", "Password reset link sent to your email");
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }


  void _checkInactivity() {
    final now = DateTime.now();
    if (now.difference(lastActivity.value).inMinutes >= 60) {
      logout();
    }
  }
  // Keep this in your auth controller for future debugging
  void printAuthState() {
    debugPrint('''
  Auth State:
  - User: ${auth.currentUser?.uid}
  - Role: $userRole
  - Profile Complete: $isProfileComplete
  ''');
  }
}
