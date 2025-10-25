// controllers/auth_controller.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Platform-specific imports
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart'; // Commented out - Apple development not registered yet
import 'package:task/controllers/admin_controller.dart';
import 'package:task/service/firebase_service.dart';
import 'package:task/service/presence_service.dart';
import 'package:task/service/firebase_storage_service.dart';
import 'package:task/utils/snackbar_utils.dart';
import 'package:task/service/user_cache_service.dart';
import 'package:task/service/fcm_helper.dart';
import 'package:task/utils/constants/app_constants.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find<AuthController>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn? _googleSignIn = kIsWeb ? null : GoogleSignIn();

  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseStorageService storageService = FirebaseStorageService();

  RxMap<String, dynamic> userData = <String, dynamic>{}.obs;

  // Single source of truth for current user
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
  var phoneNumber = "".obs;
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
    "Driver",
    "Librarian",
    "Assignment Editor",
    "Head of Department",
    "Head of Unit",
    "Admin",
    "News Director",
    "Assistant News Director",
    "Producer",
    "Anchor",
    "Business Reporter",
    "Political Reporter",
    "Digital Reporter",
    "Web Producer"
  ];
  bool get isLoggedIn => currentUser != null;

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

    // Initialize Firebase Auth state immediately
    user.value = _auth.currentUser;
    _setupAuthStateListener();
    
    // If we have a current user, initialize their session
    if (_auth.currentUser != null) {
      debugPrint("AuthController: Current user exists, initializing session");
      _initializeUserSession();
    } else {
      debugPrint("AuthController: No current user");
    }
  }

  void _setupAuthStateListener() {
    debugPrint("AuthController: Setting up auth state listener");
    
    // Subscribe to Firebase Auth state changes
    _auth.authStateChanges().listen((User? firebaseUser) async {
      debugPrint("AuthController: Auth state changed - User: ${firebaseUser?.uid ?? 'null'}");
      
      // Update our observable
      user.value = firebaseUser;
      
      if (firebaseUser != null) {
        try {
          // Ensure user profile exists before loading data
          await _ensureUserProfileExists(firebaseUser);

          // Load user data and set presence
          await loadUserData(forceRefresh: true);
          await _handlePresence(true);
        } catch (e) {
          debugPrint("AuthController: Error handling auth state change: $e");
          // Avoid immediate logout on permission-denied; try to recover
          if (e.toString().contains("permission-denied")) {
            debugPrint("AuthController: Permission denied while handling auth change; will stay signed in and show limited UI");
            // Show message to user
            _safeSnackbar("Access Denied", "You don't have access to this data.");
          }
        }
      } else {
        // User signed out or auth error
        await _handlePresence(false);
        resetUserData();
      }
    }, onError: (error) {
      debugPrint("AuthController: Auth state error: $error");
      _handlePresence(false);
      resetUserData();
    });

    // NOTE: single authStateChanges listener is used above. Avoid adding
    // duplicate listeners which can cause race conditions and unexpected
    // sign-outs during login. Additional sign-in/sign-out handling should
    // be performed inside the primary listener above (which does async
    // initialization work).
  }

  // ignore: unused_element
  void _handleUserSignOut() {
    // Reset user data
    resetUserData();

    // Set presence offline
    _handlePresence(false);

    // Clear any cached data for the signed out user
    try {
      if (Get.isRegistered<UserCacheService>()) {
        final cache = Get.find<UserCacheService>();
        cache.clearCache();
      }
    } catch (e) {
      debugPrint("AuthController: Error clearing cache on sign out: $e");
    }
  }

  // ignore: unused_element
  void _handleUserSignIn(User userValue) {
    // Set presence online
    _handlePresence(true);

    // Load user data if profile is complete
    if (isProfileComplete.value) {
      // Reload user data to ensure it's fresh
      loadUserData(forceRefresh: true);
    }
  }

  @override
  void onReady() {
    // Delay Firebase auth state binding to prevent premature operations
    Future.delayed(const Duration(milliseconds: 500), () {
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
        role == 'Head of Unit' ||
        role == 'News Director' ||
        role == 'Assistant News Director';
  }

  void goToHome() {
    final role = userRole.value;
    if (role == "Admin" ||
        role == "Assignment Editor" ||
        role == "Head of Department" ||
        role == "Head of Unit") {
      Get.offAllNamed('/admin-dashboard');
    } else if (role == "Librarian") {
      Get.offAllNamed('/librarian-dashboard');
    } else if (role == "Reporter" ||
        role == "Cameraman" ||
        role == "Driver" ||
        role == "Producer" ||
        role == "Anchor" ||
        role == "Business Reporter" ||
        role == "Political Reporter" ||
        role == "Digital Reporter" ||
        role == "Web Producer") {
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
        debugPrint(
            "AuthController: PresenceService not initialized, skipping presence update");
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
        } else if (userRole.value.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await navigateBasedOnRole();
          });
        } else {
          debugPrint(
              "AuthController: Profile complete but userRole is empty, cannot navigate");
          showSnackbar("Login Error",
              "Your user role is missing. Please contact support.");
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
      if (Get.isRegistered<AdminController>()) {
        final adminController = Get.find<AdminController>();
        await adminController
            .fetchAdminProfile()
            .timeout(Duration(seconds: 10));
      }
    } catch (e) {
      debugPrint("Admin verification optional: $e");
      // Don't logout - make admin features optional
    }
  }

  // Enhanced loadUserData with caching for better performance
  Future<void> loadUserData({bool forceRefresh = false}) async {
    debugPrint(
        "AuthController: Starting loadUserData (forceRefresh: $forceRefresh)");
    if (_auth.currentUser == null) {
      debugPrint("AuthController: No current user, returning");
      return;
    }
    try {
      // Ensure profile exists before trying to read
      await _ensureUserProfileExists(_auth.currentUser!);

      // Always fetch fresh data from Firestore before navigation
      debugPrint("AuthController: Fetching fresh user data from Firestore");
      final userDoc = await _firestore
          .collection("users")
          .doc(_auth.currentUser!.uid)
          .get();
      if (userDoc.exists) {
        debugPrint("AuthController: Fresh user document exists, updating data");
        final data = userDoc.data()!;
        _updateUserDataFromMap(data);
        // Optionally update cache
        final userCacheService = Get.find<UserCacheService>();
        await userCacheService.updateCurrentUserData(data);
        debugPrint(
            "AuthController: Fresh user data loaded and cached successfully");
        debugPrint(
            "AFTER LOAD: isProfileComplete=${isProfileComplete.value}, userRole=${userRole.value}, currentRoute=${Get.currentRoute}");
        return;
      } else {
        debugPrint(
            "AuthController: User document does not exist for ${_auth.currentUser!.uid}");
        resetUserData();
        throw Exception("User document not found");
      }
    } catch (e) {
      debugPrint("AuthController: Critical error in loadUserData: $e");
      // If we have cached data, use it as fallback
      final userCacheService = Get.find<UserCacheService>();
      final cachedData = await userCacheService.getCurrentUserData();
      if (cachedData != null) {
        debugPrint("AuthController: Using cached data as fallback");
        _updateUserDataFromMap(cachedData);
        return;
      }
      resetUserData();
      rethrow;
    }
  }

  // Helper method to update user data from a map
  void _updateUserDataFromMap(Map<String, dynamic> data) {
    fullName.value = data['fullName'] ?? '';
    profilePic.value = data['photoUrl'] ?? '';
    phoneNumber.value = data['phoneNumber'] ?? '';
    userRole.value = data['role'] ?? '';
    setUserRole(userRole.value);
    isProfileComplete.value = data['profileComplete'] ?? false;
    userData.assignAll(data);
  }

  void resetUserData() {
    fullName.value = '';
    profilePic.value = '';
    phoneNumber.value = '';
    userRole.value = '';
    isProfileComplete.value = false;
    userData.clear();
  }

  /// Hide sensitive UI data when app backgrounds (keeps Firebase session active)
  void hideSensitiveUserData() {
    debugPrint('AuthController: Hiding sensitive UI data');
    fullName.value = '';
    profilePic.value = '';
    phoneNumber.value = '';
    // Note: We don't clear userRole, isProfileComplete, or userData
    // to preserve session state for when user returns with biometrics
  }

  // Complete profile and navigate to appropriate screen
  Future<void> completeProfile() async {
    try {
      isLoading(true);
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
      phoneNumber.value = phoneNumberController.text.trim();
      setUserRole(selectedRole.value);
      isProfileComplete.value = true;

      debugPrint("AuthController: Profile completed successfully");
      debugPrint("AuthController: User role: ${userRole.value}");
      debugPrint(
          "AuthController: Profile complete: ${isProfileComplete.value}");

      // Load user data and navigate to correct dashboard
      await loadUserData(forceRefresh: true);
      await navigateBasedOnRole();
    } catch (e) {
      debugPrint("AuthController: Profile completion error: $e");
      _safeSnackbar("Error", "Failed to complete profile: ${e.toString()}");
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  // Simplified navigateBasedOnRole method
  Future<void> navigateBasedOnRole() async {
    // Ensure role is loaded before navigation
    int attempts = 0;
    while (userRole.value.isEmpty && attempts < 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
    }

    final role = userRole.value;
    debugPrint("Navigating based on role: $role");

    if (role == "Admin" ||
        role == "Assignment Editor" ||
        role == "Head of Department" ||
        role == "News Director" ||
        role == "Assistant News Director" ||
        role == "Head of Unit") {
      Get.offAllNamed('/admin-dashboard');
    } else if (role == "Librarian") {
      Get.offAllNamed('/librarian-dashboard');
    } else if (role == "Reporter" ||
        role == "Cameraman" ||
        role == "Driver" ||
        role == "Producer" ||
        role == "Anchor" ||
        role == "Business Reporter" ||
        role == "Political Reporter" ||
        role == "Digital Reporter" ||
        role == "Web Producer") {
      Get.offAllNamed('/home');
    } else {
      debugPrint(
          "AuthController: No valid role found ($role), navigating to login");
      Get.offAllNamed('/login');
    }
  }

  void setBuildPhase(bool inBuildPhase) {
    // This method is kept for compatibility but no longer used
  }

  void resetLoadingState() {
    debugPrint("AuthController: Resetting loading state");
    isLoading(false);
  }

  Future<void> signUp(
      String userFullName, String email, String password, String role) async {
    try {
      isLoading(true);

      // Try to create the user directly
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If we get here, user was created successfully
      final user = userCredential.user;
      if (user != null) {
        // Update user profile with display name
        await user.updateDisplayName(userFullName);
        await user.reload();

        // Get FCM token for notifications
        final fcmToken = await FCMHelper.getFCMToken();

        // Save additional user data to Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'fullName': userFullName,
          'role': role,
          'fcmToken': fcmToken ?? "",
          'profileComplete': false,
          'photoUrl': "",
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update the local user role
        userRole.value = role;
        // Load user data from Firestore to ensure userRole is set
        await loadUserData(forceRefresh: true);
        // Navigate based on the user's role
        await navigateBasedOnRole();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _safeSnackbar(
            'Error', 'The email address is already in use by another account.');
      } else {
        _safeSnackbar('Error', e.message ?? 'An error occurred during sign up');
      }
    } catch (e) {
      _safeSnackbar('Error', 'An unexpected error occurred');
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
        String? fcmToken;
        if (!kIsWeb) {
          try {
            // Request permissions first
            final settings = await FirebaseMessaging.instance.requestPermission(
              alert: true,
              badge: true,
              sound: true,
            );

            if (settings.authorizationStatus ==
                    AuthorizationStatus.authorized ||
                settings.authorizationStatus ==
                    AuthorizationStatus.provisional) {
              fcmToken = await FCMHelper.getFCMToken();
            } else {
              debugPrint(
                  "⚠️ Notification permissions not granted during admin signup: ${settings.authorizationStatus}");
            }
          } catch (e) {
            debugPrint("❌ Error getting FCM Token during admin signup: $e");
          }
        }

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

        // Set custom claim for admin
        try {
          await FirebaseFunctions.instance.httpsCallable('setAdminClaim').call({
            'uid': user.uid,
          });
        } catch (e) {
          debugPrint("Error setting admin claim: $e");
          // Continue even if claim setting fails
        }

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

      // Get FCM token for notifications
      String? fcmToken;
      if (!kIsWeb) {
        try {
          // Request permissions first
          final settings = await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );

          if (settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional) {
            fcmToken = await FCMHelper.getFCMToken();
          } else {
            debugPrint(
                "⚠️ Notification permissions not granted during createAdminUser: ${settings.authorizationStatus}");
          }
        } catch (e) {
          debugPrint("❌ Error getting FCM Token during createAdminUser: $e");
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'uid': credential.user!.uid,
        'email': email,
        'fullName': fullName,
        'role': 'admin',
        'fcmToken': fcmToken ?? "",
        'profileComplete': false,
        'photoUrl': "",
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Set custom claim for admin
      try {
        await FirebaseFunctions.instance.httpsCallable('setAdminClaim').call({
          'uid': credential.user!.uid,
        });
      } catch (e) {
        debugPrint("Error setting admin claim: $e");
        // Continue even if claim setting fails
      }

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

      // Verify user is still authenticated before proceeding with storage operations
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _safeSnackbar("Error", "Authentication lost during upload.");
        return;
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
        userId: currentUser.uid,
      );

      if (downloadUrl != null) {
        // Save the Firebase Storage URL in Firestore user profile
        await _firestore.collection('users').doc(currentUser.uid).update({
          'photoUrl': downloadUrl,
        });

        profilePic.value = downloadUrl;

        // Update cache with new profile picture
        try {
          final userCacheService = Get.find<UserCacheService>();
          await userCacheService.updateUserAvatar(currentUser.uid, downloadUrl);
          debugPrint("AuthController: Profile picture cache updated");
        } catch (e) {
          debugPrint(
              "AuthController: Failed to update profile picture cache: $e");
        }

        debugPrint("AuthController: Profile picture updated successfully");
        _safeSnackbar("Success", "Profile picture updated successfully.");
      } else {
        debugPrint("AuthController: Profile picture upload failed");
        _safeSnackbar("Upload Failed", "Could not upload the image. Please check your connection and try again.");
      }
    } catch (e) {
      debugPrint("AuthController: Profile picture upload error: $e");

      // Handle specific authentication errors
      if (e.toString().contains('unauthorized') ||
          e.toString().contains('not authenticated')) {
        _safeSnackbar("Authentication Error", "Please log in again to upload profile pictures.");
      } else {
        _safeSnackbar("Upload Failed", "Error: ${e.toString()}");
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Profile picture upload using bytes (for web platform)
  Future<void> uploadProfilePictureFromBytes(
      Uint8List bytes, String fileName) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      _safeSnackbar("Error", "User not logged in.");
      return;
    }

    try {
      isLoading.value = true;
      debugPrint("AuthController: Starting profile picture upload from bytes");

      // Verify user is still authenticated before proceeding with storage operations
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _safeSnackbar("Error", "Authentication lost during upload.");
        return;
      }

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
        userId: currentUser.uid,
      );

      if (downloadUrl != null) {
        // Save the Firebase Storage URL in Firestore user profile
        await _firestore.collection('users').doc(currentUser.uid).update({
          'photoUrl': downloadUrl,
        });

        profilePic.value = downloadUrl;

        // Update cache with new profile picture
        try {
          final userCacheService = Get.find<UserCacheService>();
          await userCacheService.updateUserAvatar(currentUser.uid, downloadUrl);
          debugPrint("AuthController: Profile picture cache updated");
        } catch (e) {
          debugPrint(
              "AuthController: Failed to update profile picture cache: $e");
        }

        debugPrint("AuthController: Profile picture updated successfully");
        _safeSnackbar("Success", "Profile picture updated successfully.");
      } else {
        debugPrint("AuthController: Profile picture upload failed");
        _safeSnackbar("Upload Failed", "Could not upload the image. Please check your connection and try again.");
      }
    } catch (e) {
      debugPrint("AuthController: Profile picture upload error: $e");

      // Handle specific authentication errors
      if (e.toString().contains('unauthorized') ||
          e.toString().contains('not authenticated')) {
        _safeSnackbar("Authentication Error", "Please log in again to upload profile pictures.");
      } else {
        _safeSnackbar("Upload Failed", "Error: ${e.toString()}");
      }
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

      final updatedData = {
        'fullName': fullNameController.text.trim(),
        'phoneNumber': phoneNumberController.text.trim(),
        'role': selectedRole.value,
        'profileComplete': true,
      };

      await _firebaseService.updateUserData(user.uid, updatedData);

      fullName.value = fullNameController.text.trim();
      phoneNumber.value = phoneNumberController.text.trim();
      setUserRole(selectedRole.value);
      isProfileComplete.value = true;

      // Update cache with new profile data
      try {
        final userCacheService = Get.find<UserCacheService>();
        await userCacheService.updateUserInfo(user.uid,
            fullName: fullNameController.text.trim());

        // Get current cached data and merge with updates
        final currentCachedData =
            await userCacheService.getCurrentUserData() ?? {};
        await userCacheService.updateCurrentUserData({
          ...currentCachedData,
          ...updatedData,
        });
        debugPrint("AuthController: Profile data cache updated");
      } catch (e) {
        debugPrint("AuthController: Failed to update profile data cache: $e");
      }

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
      // Request permissions first
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      String? token = await FCMHelper.getFCMToken();
      if (token != null && _auth.currentUser != null) {
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({"fcmToken": token});
        debugPrint(
            "✅ FCM Token saved to Firestore for user: ${_auth.currentUser!.uid}");
      } else {
        debugPrint("⚠️ FCM Token is null or user not authenticated");
      }
    } catch (e) {
      debugPrint("❌ Error saving FCM Token: $e");
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

      debugPrint("AuthController: User signed in successfully: ${credential.user!.uid}");

      // Wait for auth state to propagate before proceeding. Instead of a
      // fixed delay, wait for the next authStateChanges event (with a
      // short timeout) so we react to the actual propagated state.
      try {
        final User? propagatedUser = await _auth.authStateChanges().firstWhere((u) => u != null).timeout(const Duration(seconds: 3));
        if (propagatedUser == null) {
          throw Exception("Authentication lost after sign in");
        }
      } catch (e) {
        // If no propagated user arrived within the timeout, double-check
        // the currentUser and fail if it's null to surface a clear error.
        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          throw Exception("Authentication lost after sign in");
        }
      }

  final currentUser = _auth.currentUser!;
  debugPrint("AuthController: Loading user data for user: ${currentUser.uid}");
  await loadUserData();

      debugPrint("AuthController: Setting lastActivity");
      lastActivity.value = DateTime.now();

      debugPrint("AuthController: Setting presence to online");
      try {
        await _handlePresence(true);
        debugPrint("AuthController: Presence set successfully");
      } catch (e) {
        debugPrint("AuthController: Presence setting failed, continuing: $e");
      }

      debugPrint("AuthController: User data loaded - Profile complete: ${isProfileComplete.value}, Role: ${userRole.value}");

      // Use a post-frame callback to ensure navigation happens after the current build phase
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!isProfileComplete.value) {
          debugPrint("AuthController: Navigating to profile update");
          Get.offAllNamed("/profile-update");
        } else {
          // Ensure role is loaded before navigation
          int attempts = 0;
          while (userRole.value.isEmpty && attempts < 10) {
            debugPrint("AuthController: Waiting for user role to load (attempt ${attempts + 1})");
            await Future.delayed(const Duration(milliseconds: 200));
            attempts++;
          }

          if (userRole.value.isNotEmpty) {
            debugPrint("AuthController: Profile is complete, navigating based on role: ${userRole.value}");
            await navigateBasedOnRole();
          } else {
            debugPrint("AuthController: Role still empty after waiting, navigating to login");
            Get.offAllNamed('/login');
          }
        }
      });
    } on FirebaseAuthException catch (e) {
      isLoading(false);
      debugPrint("AuthController: Firebase auth error: ${e.message}");
      _safeSnackbar("Error", _handleAuthError(e));
      rethrow;
    } catch (e) {
      isLoading(false);
      debugPrint("AuthController: General error during sign in: $e");
      _safeSnackbar("Error", "Sign in failed: $e");
      rethrow;
    }
  }

  // Google Sign-In Method
  Future<void> signInWithGoogle() async {
    try {
      isLoading(true);
      debugPrint("AuthController: Starting Google sign-in");

      if (_googleSignIn == null) {
        debugPrint(
            "AuthController: Google Sign-In not available on this platform");
        _safeSnackbar("Error", "Google Sign-In not available on this platform");
        isLoading(false);
        return;
      }

      // Trigger the authentication flow
      debugPrint("AuthController: Calling _googleSignIn.signIn()");
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        debugPrint("AuthController: Google sign-in canceled by user");
        isLoading(false);
        return;
      }

      // Obtain the auth details from the request
      debugPrint("AuthController: Getting Google authentication details");
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      debugPrint(
          "AuthController: Got access token: ${googleAuth.accessToken != null}");
      debugPrint("AuthController: Got ID token: ${googleAuth.idToken != null}");

      // Create a new credential
      debugPrint("AuthController: Creating Firebase credential");
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      debugPrint(
          "AuthController: Signing in to Firebase with Google credential");
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      debugPrint("AuthController: Firebase sign-in successful");

      if (userCredential.user == null) {
        throw Exception("No user returned from Google sign in");
      }

      // Check if this is a new user
      final bool isNewUser =
          userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser) {
        await _createDefaultUserProfile(userCredential.user!);
        _safeSnackbar('Success', 'Account created successfully with Google!');
        Get.offAllNamed("/profile-update");
      } else {
        // Existing user, load their data
        await loadUserData();
        lastActivity.value = DateTime.now();

        try {
          await _handlePresence(true);
        } catch (e) {
          debugPrint("Presence setting failed: $e");
        }

        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!isProfileComplete.value) {
            Get.offAllNamed("/profile-update");
          } else {
            // Ensure role is loaded before navigation
            int attempts = 0;
            while (userRole.value.isEmpty && attempts < 10) {
              debugPrint(
                  "AuthController: Waiting for user role to load (attempt ${attempts + 1})");
              await Future.delayed(const Duration(milliseconds: 200));
              attempts++;
            }
            debugPrint(
                "AuthController: Role loaded: ${userRole.value}, navigating...");
            await navigateBasedOnRole();
          }
        });
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("Google sign in Firebase error: ${e.message}");
      _safeSnackbar("Error", _handleAuthError(e));
    } catch (e) {
      debugPrint("Google sign in error: $e");
      _safeSnackbar("Error", "Google sign in failed: $e");
    } finally {
      isLoading(false);
    }
  }

  Future<void> assignTask(String taskId, String userId) async {
    try {
      isLoading.value = true;
      final taskRef =
          FirebaseFirestore.instance.collection('tasks').doc(taskId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final taskSnapshot = await transaction.get(taskRef);

        if (!taskSnapshot.exists) {
          throw Exception("Task does not exist!");
        }

        List<dynamic> assignedUsers =
            taskSnapshot.data()?['assignedUsers'] ?? [];

        if (assignedUsers.contains(userId)) {
          _safeSnackbar("Info", "User is already assigned to this task.");
          return;
        }

        if (assignedUsers.length >= 3) {
          _safeSnackbar(
              "Error", "This task has already been assigned to 3 users.");
          return;
        }

        assignedUsers.add(userId);

        transaction.update(taskRef, {'assignedUsers': assignedUsers});
      });

      _safeSnackbar("Success", "Task assigned successfully.");
    } catch (e) {
      _safeSnackbar("Error", "Failed to assign task: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;

      // Preserve current uid for targeted cache clearing
      final String? uid = _auth.currentUser?.uid;

      // 1. First reset local state immediately
      resetUserData();

      // 1b. Clear any cached user data to avoid cross-user leakage
      try {
        if (Get.isRegistered<UserCacheService>()) {
          final cache = Get.find<UserCacheService>();
          if (uid != null) {
            await cache.clearUserCache(uid);
          }
          await cache.clearCache();
        }
      } catch (e) {
        debugPrint(
            "AuthController: Failed clearing user cache during logout: $e");
      }

      // 2. Then handle presence and auth signout
      await Future.wait([
        _handlePresence(false),
        _auth.signOut(),
      ]);

      // 3. Ensure complete cleanup before navigation
      await Future.delayed(const Duration(milliseconds: 200));

      // 4. Navigate immediately to login screen - no post-frame callback needed
      // The auth state listener will handle any additional UI updates
      Get.offAllNamed("/login", arguments: {'fromLogout': true});
    } catch (e) {
      _safeSnackbar("Error", "Logout failed: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      isLoading.value = true;

      // Preserve current uid for targeted cache clearing
      final String? uid = _auth.currentUser?.uid;

      // Reset local observable state immediately
      resetUserData();

      // Clear any cached user data to avoid cross-user leakage
      try {
        if (Get.isRegistered<UserCacheService>()) {
          final cache = Get.find<UserCacheService>();
          if (uid != null) {
            await cache.clearUserCache(uid);
          }
          await cache.clearCache();
        }
      } catch (e) {
        debugPrint(
            "AuthController: Failed clearing user cache during signOut: $e");
      }

      // Presence offline and Firebase sign out in parallel
      await Future.wait([
        _handlePresence(false),
        _auth.signOut(),
      ]);

      // Give a tiny buffer to let listeners settle
      await Future.delayed(const Duration(milliseconds: 200));

      // Navigate immediately to login screen - no post-frame callback needed
      Get.offAllNamed('/login', arguments: {'fromLogout': true});
    } catch (e) {
      _safeSnackbar('Error', 'Sign out failed: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
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

  // Email Link Authentication Methods
  Future<void> sendSignInLinkToEmail(String email) async {
    try {
      isLoading(true);

      // Configure the action code settings
      final ActionCodeSettings actionCodeSettings = ActionCodeSettings(
        // URL you want to redirect back to. This should be a deep link to your app
        // For development, you can use a custom URL scheme
        url: ExternalUrls.emailLinkAuthUrl,
        // This must be true for email link authentication
        handleCodeInApp: true,
        iOSBundleId: 'com.example.task',
        androidPackageName: 'com.example.task',
        // Install the app if it's not already installed
        androidInstallApp: true,
        androidMinimumVersion: '21',
      );

      await _auth.sendSignInLinkToEmail(
        email: email.trim(),
        actionCodeSettings: actionCodeSettings,
      );

      // Save the email locally so you can complete sign in on the same device
      await _saveEmailForSignIn(email.trim());

      _safeSnackbar("Success", "Authentication link sent to your email");
    } on FirebaseAuthException catch (e) {
      debugPrint("AuthController: Firebase auth error: ${e.message}");
      _safeSnackbar("Error", _handleAuthError(e));
      rethrow;
    } catch (e) {
      debugPrint("AuthController: General error during send sign in link: $e");
      _safeSnackbar("Error", "Failed to send authentication link: $e");
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  Future<void> signInWithEmailLink(String email, String emailLink) async {
    try {
      isLoading(true);

      // Confirm the link is a sign-in with email link.
      if (!_auth.isSignInWithEmailLink(emailLink)) {
        throw Exception("Invalid email link");
      }

      final UserCredential credential = await _auth.signInWithEmailLink(
        email: email.trim(),
        emailLink: emailLink,
      );

      if (credential.user == null) throw Exception("No user returned");

      debugPrint("AuthController: User signed in with email link successfully");
      await loadUserData();
      lastActivity.value = DateTime.now();

      try {
        await _handlePresence(true);
        debugPrint("AuthController: Presence set successfully");
      } catch (e) {
        debugPrint("AuthController: Presence setting failed, continuing: $e");
      }

      // Clear the saved email
      await _clearSavedEmail();

      // Navigate based on profile completion and role
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!isProfileComplete.value) {
          debugPrint("AuthController: Navigating to profile update");
          Get.offAllNamed("/profile-update");
        } else {
          // Navigate based on role
          await navigateBasedOnRole();
        }
      });
    } on FirebaseAuthException catch (e) {
      debugPrint("AuthController: Firebase auth error: ${e.message}");
      _safeSnackbar("Error", _handleAuthError(e));
      rethrow;
    } catch (e) {
      debugPrint("AuthController: General error during email link sign in: $e");
      _safeSnackbar("Error", "Email link sign in failed: $e");
      rethrow;
    } finally {
      isLoading(false);
    }
  }

  // Helper method to save email for sign in
  Future<void> _saveEmailForSignIn(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('emailForSignIn', email);
    } catch (e) {
      debugPrint("Error saving email for sign in: $e");
    }
  }

  // Helper method to get saved email
  Future<String?> getSavedEmailForSignIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('emailForSignIn');
    } catch (e) {
      debugPrint("Error getting saved email: $e");
      return null;
    }
  }

  // Helper method to clear saved email
  Future<void> _clearSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('emailForSignIn');
    } catch (e) {
      debugPrint("Error clearing saved email: $e");
    }
  }

  void _checkInactivity() {
    // Automatic logout disabled to keep users logged in
    // Users can manually logout if needed
    final now = DateTime.now();
    debugPrint(
        'Inactivity check: ${now.difference(lastActivity.value).inMinutes} minutes since last activity');
    // Note: Automatic logout has been disabled for better user experience
    // Users will remain logged in until they manually logout
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

  // Ensure a minimal user profile exists for strict rules environments
  Future<void> _ensureUserProfileExists(User firebaseUser) async {
    final docRef = _firestore.collection('users').doc(firebaseUser.uid);
    final snap = await docRef.get();
    if (!snap.exists) {
      await _createDefaultUserProfile(firebaseUser);
    }
  }

  Future<void> _createDefaultUserProfile(User firebaseUser) async {
    String? fcmToken;
    if (!kIsWeb) {
      try {
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          fcmToken = await FCMHelper.getFCMToken();
        }
      } catch (_) {}
    }

    await _firestore.collection('users').doc(firebaseUser.uid).set({
      'uid': firebaseUser.uid,
      'email': firebaseUser.email ?? '',
      'fullName': firebaseUser.displayName ?? '',
      'role': 'Reporter',
      'fcmToken': fcmToken ?? "",
      'profileComplete': false,
      'photoUrl': firebaseUser.photoURL ?? "",
      'createdAt': FieldValue.serverTimestamp(),
      'authProvider': 'google',
    }, SetOptions(merge: true));

    userRole.value = 'Reporter';
    fullName.value = firebaseUser.displayName ?? '';
    profilePic.value = firebaseUser.photoURL ?? '';
  }
}
