// controllers/auth_controller.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/admin_controller.dart';
import 'package:task/service/firebase_service.dart';
import 'package:task/service/presence_service.dart';
import 'package:task/service/firebase_storage_service.dart';
import 'package:task/utils/snackbar_utils.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find<AuthController>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseStorageService storageService = FirebaseStorageService();

  Rx<User?> firebaseUser = Rx<User?>(null);
  RxMap<String, dynamic> userData = <String, dynamic>{}.obs;

  final Rx<User?> user = Rx<User?>(null);
  RxBool isLoginPasswordHidden = true.obs;
  RxBool isSignUpPasswordHidden = true.obs;
  RxBool isConfirmPasswordHidden = true.obs;
 
  // Add a flag to track if the app is ready for snackbars

  User? get currentUser => user.value ?? _auth.currentUser;

  FirebaseAuth get auth => _auth;
  FirebaseService get firebaseService => _firebaseService;

  var isLoading = false.obs;
  var fullName = "".obs;
  var profilePic = "".obs;
  var selectedRole = ''.obs;
  var userRole = ''.obs;
  var isProfileComplete = false.obs;
  final lastActivity = DateTime.now().obs;
  final isAdmin = false.obs;
  final canCreateTasks = false.obs;
  

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

  // Safe snackbar method that checks if app is ready
  void _safeSnackbar(String title, String message) {
    SnackbarUtils.showSnackbar(title, message);
  }

  // Replace all direct Get.snackbar calls with this method
  void showSnackbar(String title, String message) {
    SnackbarUtils.showSnackbar(title, message);
  }

  // Method to mark app as ready (called from MyApp after initialization)
  void markAppAsReady() {
    debugPrint("AuthController: App marked as ready for snackbars");
  }

  void setUserRole(String role) {
    userRole.value = role;
    isAdmin.value = role == 'Admin';
    canCreateTasks.value = true;
  }

  @override
  void onInit() {
    super.onInit();
    debugPrint("AuthController: onInit called");
    // Ensure loading state is false on initialization
    isLoading(false);
    
    // Initialize observables with safe default values
    fullName.value = "";
    profilePic.value = "";
    selectedRole.value = "";
    userRole.value = "";
    isProfileComplete.value = false;
    
    // Initialize user observable with current Firebase user
    user.value = _auth.currentUser;
    
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
    // Delay Firebase auth state binding to prevent premature operations
    Future.delayed(const Duration(milliseconds: 500), () {
      firebaseUser.bindStream(_auth.authStateChanges());
      user.bindStream(_auth.authStateChanges());
      // Temporarily disable automatic role-based navigation to prevent build phase issues
      // debounce(userRole, (_) => _handleRoleChange(), time: const Duration(milliseconds: 100));
      debounce(lastActivity, (_) => _checkInactivity(),
          time: const Duration(minutes: 30));
    });
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
      if (presence.isInitialized) {
        if (isOnline) {
          await presence.setOnline();
        } else {
          await presence.setOffline();
        }
      } else {
        debugPrint("AuthController: PresenceService not initialized, skipping presence update");
      }
    } else {
      debugPrint("AuthController: PresenceService not registered");
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
          setUserRole(userRole.value);
          isProfileComplete.value = data['profileComplete'] ?? false;

          userData.assignAll(data);
          debugPrint("AuthController: User data loaded successfully");
          debugPrint("AFTER LOAD: isProfileComplete=${isProfileComplete.value}, userRole=${userRole.value}, currentRoute=${Get.currentRoute}");
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

  // Complete profile and navigate to appropriate screen
  Future<void> completeProfile() async {
    try {
      debugPrint("AuthController: Starting profile completion");
      if (_auth.currentUser == null) {
        _safeSnackbar("Error", "User not logged in");
        return;
      }

      // Update user profile in Firestore
      await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
        "profileComplete": true,
        "fullName": fullNameController.text.trim(),
        "phoneNumber": phoneNumberController.text.trim(),
        "role": selectedRole.value,
        "updatedAt": FieldValue.serverTimestamp(),
      });

      // Update local observables
      fullName.value = fullNameController.text.trim();
      setUserRole(selectedRole.value);
      isProfileComplete.value = true;

      debugPrint("AuthController: Profile completed successfully");
      debugPrint("AuthController: User role: ${userRole.value}");
      debugPrint("AuthController: Profile complete: ${isProfileComplete.value}");

      // Show SaveSuccessScreen after profile completion
      Get.toNamed('/save-success');
    } catch (e) {
      debugPrint("AuthController: Profile completion error: $e");
      _safeSnackbar("Error", "Failed to complete profile: ${e.toString()}");
      rethrow;
    }
  }

  // Simplified navigateBasedOnRole method
  void navigateBasedOnRole() {
    debugPrint("🚀 navigateBasedOnRole called");
    debugPrint("🚀 navigateBasedOnRole: isProfileComplete=${isProfileComplete.value}, userRole=${userRole.value}, currentRoute=${Get.currentRoute}");
    
    // Use post-frame callback to ensure safe navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = userRole.value;
      debugPrint("🚀 Navigating based on role: $role");

      try {
        if (["Admin", "Assignment Editor", "Head of Department"].contains(role)) {
          debugPrint("🚀 Navigating to admin-dashboard");
          Get.offAllNamed("/admin-dashboard");
        } else if (["Reporter", "Cameraman"].contains(role)) {
          debugPrint("🚀 Navigating to home");
          Get.offAllNamed("/home");
        } else {
          debugPrint("🚀 Navigating to login (fallback) - role was: '$role'");
          Get.offAllNamed("/login");
        }
        debugPrint("🚀 Navigation call completed");
      } catch (e) {
        debugPrint("🚀 Navigation error: $e");
        // Fallback to login
        Get.offAllNamed("/login");
      }
    });
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
      _safeSnackbar("Error", _handleAuthError(e));
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
      _safeSnackbar("Error", "Failed to create admin account: ${e.toString()}");
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

      _safeSnackbar('Success', 'Admin user created');
    } on FirebaseAuthException catch (e) {
      _safeSnackbar('Error', e.message ?? 'Admin creation failed');
    }
  }

  /// Profile picture upload using Firebase Storage
  Future<void> uploadProfilePicture(File imageFile) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      _safeSnackbar("Error", "User not logged in.");
      return;
    }

    try {
      isLoading.value = true;
      debugPrint("AuthController: Starting profile picture upload");

      if (!await imageFile.exists()) {
        throw Exception("Image file doesn't exist");
      }

      // Delete old profile picture if it exists
      String oldPhotoUrl = profilePic.value;
      if (oldPhotoUrl.isNotEmpty) {
        debugPrint("AuthController: Deleting old profile picture");
        await storageService.deleteProfilePicture(oldPhotoUrl);
      }

      // Upload new profile picture to Firebase Storage
      debugPrint("AuthController: Uploading new profile picture");
      final downloadUrl = await storageService.uploadProfilePicture(
        imageFile: imageFile,
        userId: user.uid,
      );

      if (downloadUrl != null) {
        // Save the Firebase Storage URL in Firestore user profile
        await _firestore.collection('users').doc(user.uid).update({
          'photoUrl': downloadUrl,
        });

        profilePic.value = downloadUrl;
        debugPrint("AuthController: Profile picture updated successfully");
        _safeSnackbar("Success", "Profile picture updated successfully.");
      } else {
        debugPrint("AuthController: Profile picture upload failed");
        _safeSnackbar("Upload Failed", "Could not upload the image.");
      }
    } catch (e) {
      debugPrint("AuthController: Profile picture upload error: $e");
      _safeSnackbar("Upload Failed", "Error: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  /// Profile picture upload using bytes (for web platform)
  Future<void> uploadProfilePictureFromBytes(Uint8List bytes, String fileName) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      _safeSnackbar("Error", "User not logged in.");
      return;
    }

    try {
      isLoading.value = true;
      debugPrint("AuthController: Starting profile picture upload from bytes");

      // Delete old profile picture if it exists
      String oldPhotoUrl = profilePic.value;
      if (oldPhotoUrl.isNotEmpty) {
        debugPrint("AuthController: Deleting old profile picture");
        await storageService.deleteProfilePicture(oldPhotoUrl);
      }

      // Upload new profile picture to Firebase Storage
      debugPrint("AuthController: Uploading new profile picture from bytes");
      final downloadUrl = await storageService.uploadProfilePictureFromBytes(
        bytes: bytes,
        fileName: fileName,
        userId: user.uid,
      );

      if (downloadUrl != null) {
        // Save the Firebase Storage URL in Firestore user profile
        await _firestore.collection('users').doc(user.uid).update({
          'photoUrl': downloadUrl,
        });

        profilePic.value = downloadUrl;
        debugPrint("AuthController: Profile picture updated successfully");
        _safeSnackbar("Success", "Profile picture updated successfully.");
      } else {
        debugPrint("AuthController: Profile picture upload failed");
        _safeSnackbar("Upload Failed", "Could not upload the image.");
      }
    } catch (e) {
      debugPrint("AuthController: Profile picture upload error: $e");
      _safeSnackbar("Upload Failed", "Error: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfileDetails() async {
    final user = _auth.currentUser;
    if (user == null) {
      _safeSnackbar('Error', 'No user signed in');
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
      setUserRole(selectedRole.value);
      isProfileComplete.value = true;

      _safeSnackbar('Success', 'Profile updated successfully');
    } catch (e) {
      _safeSnackbar('Error', 'Failed to update profile: ${e.toString()}');
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
      debugPrint("AuthController: loadUserData completed, setting lastActivity");
      lastActivity.value = DateTime.now();
      debugPrint("AuthController: Setting presence to online");
      try {
        await _handlePresence(true); // Set presence after successful login
        debugPrint("AuthController: Presence set successfully");
      } catch (e) {
        debugPrint("AuthController: Presence setting failed, continuing: $e");
      }

      debugPrint("AuthController: User data loaded, profile complete: ${isProfileComplete.value}");
      debugPrint("AuthController: User role: ${userRole.value}");
      debugPrint("AuthController: User full name: ${fullName.value}");
      debugPrint("AuthController: Current route before navigation: ${Get.currentRoute}");
      
      // Use a post-frame callback to ensure navigation happens after the current build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isProfileComplete.value) {
          debugPrint("AuthController: Navigating to profile update");
          Get.offAllNamed("/profile-update");
        } else {
          debugPrint("AuthController: Profile is complete, navigating based on role");
          final role = userRole.value;
          if (["Admin", "Assignment Editor", "Head of Department"].contains(role)) {
            debugPrint("AuthController: Navigating to admin-dashboard");
            Get.offAllNamed("/admin-dashboard");
          } else if (["Reporter", "Cameraman"].contains(role)) {
            debugPrint("AuthController: Navigating to home");
            Get.offAllNamed("/home");
          } else {
            debugPrint("AuthController: Navigating to login (fallback)");
            Get.offAllNamed("/login");
          }
        }
      });
      debugPrint("AuthController: Navigation logic completed");
    } on FirebaseAuthException catch (e) {
      debugPrint("AuthController: Firebase auth error: ${e.message}");
      _safeSnackbar("Error", _handleAuthError(e));
      rethrow;
    } catch (e) {
      debugPrint("AuthController: General error during sign in: $e");
      _safeSnackbar("Error", "Sign in failed: $e");
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
      _safeSnackbar("Success", "Task assigned successfully.");
    } catch (e) {
      _safeSnackbar("Error", "Failed to assign task.");
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
      _safeSnackbar("Error", "Logout failed: ${e.toString()}");
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
      _safeSnackbar('Error', 'Could not delete account: $e');
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
      _safeSnackbar("Success", "Password reset link sent to your email");
    } catch (e) {
      _safeSnackbar("Error", e.toString());
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
