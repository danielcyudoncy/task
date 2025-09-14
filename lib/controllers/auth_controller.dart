// controllers/auth_controller.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class AuthController extends GetxController {
  static AuthController get to => Get.find<AuthController>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn? _googleSignIn = kIsWeb ? null : GoogleSignIn();

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
    "Admin"
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
    } else if (role == "Librarian") {
      Get.offAllNamed('/librarian-dashboard');
    } else if (role == "Reporter" || role == "Cameraman" || role == "Driver") {
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
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await navigateBasedOnRole();
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

  // Enhanced loadUserData with caching for better performance
  Future<void> loadUserData({bool forceRefresh = false}) async {
    debugPrint("AuthController: Starting loadUserData (forceRefresh: $forceRefresh)");
    
    if (_auth.currentUser == null) {
      debugPrint("AuthController: No current user, returning");
      return;
    }

    try {
      // Get UserCacheService instance
      final userCacheService = Get.find<UserCacheService>();
      
      // First, try to load from cache for immediate UI update (optimistic UI)
      if (!forceRefresh) {
        final cachedData = await userCacheService.getCurrentUserData();
        if (cachedData != null) {
          debugPrint("AuthController: Loading cached user data for immediate UI update");
          _updateUserDataFromMap(cachedData);
          debugPrint("AuthController: Cached user data loaded successfully");
          
          // If cache is still valid, return early
          if (userCacheService.lastUserDataUpdate != null &&
              DateTime.now().difference(userCacheService.lastUserDataUpdate!) < const Duration(hours: 1)) {
            debugPrint("AuthController: Cache is fresh, skipping Firebase fetch");
            return;
          }
        }
      }
      
      // Fetch fresh data from Firebase (with retry logic)
      const maxRetries = 3;
      int attempt = 0;
      
      while (attempt < maxRetries) {
        try {
          debugPrint("AuthController: Fetching fresh data from Firebase (attempt ${attempt + 1})");
          
          final userDoc = await _firestore
              .collection("users")
              .doc(_auth.currentUser!.uid)
              .get();

          if (userDoc.exists) {
            debugPrint("AuthController: Fresh user document exists, updating data");
            final data = userDoc.data()!;
            
            // Update local state
            _updateUserDataFromMap(data);
            
            // Update cache with fresh data
            await userCacheService.updateCurrentUserData(data);
            
            debugPrint("AuthController: Fresh user data loaded and cached successfully");
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
            debugPrint("AuthController: loadUserData failed after $maxRetries attempts");
            
            // If we have cached data, use it as fallback
            final cachedData = await userCacheService.getCurrentUserData();
            if (cachedData != null) {
              debugPrint("AuthController: Using cached data as fallback");
              _updateUserDataFromMap(cachedData);
              return;
            }
            
            // No cached data available, reset and rethrow
            resetUserData();
            rethrow;
          }
          debugPrint("AuthController: Retrying loadUserData in 1 second");
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    } catch (e) {
      debugPrint("AuthController: Critical error in loadUserData: $e");
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
      phoneNumber.value = phoneNumberController.text.trim();
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
  Future<void> navigateBasedOnRole() async {
    // Ensure role is loaded before navigation
    int attempts = 0;
    while (userRole.value.isEmpty && attempts < 10) {
      debugPrint("AuthController: Waiting for user role to load in navigateBasedOnRole (attempt ${attempts + 1})");
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
    }
    
    final role = userRole.value;
    debugPrint("Navigating based on role: $role");
    
    if (role == "Admin" || 
        role == "Assignment Editor" || 
        role == "Head of Department") {
      Get.offAllNamed('/admin-dashboard');
    } else if (role == "Librarian") {
      Get.offAllNamed('/librarian-dashboard');
    } else if (role == "Reporter" || 
               role == "Cameraman" || 
               role == "Driver") {
      Get.offAllNamed('/home');
    } else {
      debugPrint("AuthController: No valid role found ($role), navigating to login");
      Get.offAllNamed('/login');
    }
  }

  void setBuildPhase(bool inBuildPhase) {
    // _isInBuildPhase = inBuildPhase; // This line was removed
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
        String? fcmToken;
        if (!kIsWeb) {
          try {
            // Request permissions first
            NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
              alert: true,
              badge: true,
              sound: true,
            );
            
            if (settings.authorizationStatus == AuthorizationStatus.authorized ||
                settings.authorizationStatus == AuthorizationStatus.provisional) {
              fcmToken = await FirebaseMessaging.instance.getToken();
              debugPrint("✅ FCM Token obtained during signup: ${fcmToken?.substring(0, 20)}...");
            } else {
              debugPrint("⚠️ Notification permissions not granted during signup: ${settings.authorizationStatus}");
            }
          } catch (e) {
            debugPrint("❌ Error getting FCM Token during signup: $e");
          }
        }
        
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
        
        // Navigate based on the user's role
        await navigateBasedOnRole();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _safeSnackbar('Error', 'The email address is already in use by another account.');
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
            NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
              alert: true,
              badge: true,
              sound: true,
            );
            
            if (settings.authorizationStatus == AuthorizationStatus.authorized ||
                settings.authorizationStatus == AuthorizationStatus.provisional) {
              fcmToken = await FirebaseMessaging.instance.getToken();
              debugPrint("✅ FCM Token obtained during admin signup: ${fcmToken?.substring(0, 20)}...");
            } else {
              debugPrint("⚠️ Notification permissions not granted during admin signup: ${settings.authorizationStatus}");
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
           NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
             alert: true,
             badge: true,
             sound: true,
           );
           
           if (settings.authorizationStatus == AuthorizationStatus.authorized ||
               settings.authorizationStatus == AuthorizationStatus.provisional) {
             fcmToken = await FirebaseMessaging.instance.getToken();
             debugPrint("✅ FCM Token obtained during createAdminUser: ${fcmToken?.substring(0, 20)}...");
           } else {
             debugPrint("⚠️ Notification permissions not granted during createAdminUser: ${settings.authorizationStatus}");
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
        
        // Update cache with new profile picture
        try {
          final userCacheService = Get.find<UserCacheService>();
          await userCacheService.updateUserAvatar(user.uid, downloadUrl);
          debugPrint("AuthController: Profile picture cache updated");
        } catch (e) {
          debugPrint("AuthController: Failed to update profile picture cache: $e");
        }
        
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
        
        // Update cache with new profile picture
        try {
          final userCacheService = Get.find<UserCacheService>();
          await userCacheService.updateUserAvatar(user.uid, downloadUrl);
          debugPrint("AuthController: Profile picture cache updated");
        } catch (e) {
          debugPrint("AuthController: Failed to update profile picture cache: $e");
        }
        
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
         await userCacheService.updateUserInfo(user.uid, fullName: fullNameController.text.trim());
         
         // Get current cached data and merge with updates
         final currentCachedData = await userCacheService.getCurrentUserData() ?? {};
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
      NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null && _auth.currentUser != null) {
          debugPrint("✅ FCM Token obtained: ${token.substring(0, 20)}...");
          await _firestore
              .collection('users')
              .doc(_auth.currentUser!.uid)
              .update({"fcmToken": token});
          debugPrint("✅ FCM Token saved to Firestore for user: ${_auth.currentUser!.uid}");
        } else {
          debugPrint("⚠️ FCM Token is null or user not authenticated");
        }
      } else {
        debugPrint("⚠️ Notification permissions not granted: ${settings.authorizationStatus}");
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
          debugPrint("AuthController: Profile is complete, navigating based on role: ${userRole.value}");
          final role = userRole.value;
          if (["Admin", "Assignment Editor", "Head of Department"].contains(role)) {
            debugPrint("AuthController: Navigating to admin-dashboard");
            Get.offAllNamed("/admin-dashboard");
          } else if (role == "Librarian") {
            debugPrint("AuthController: Navigating to librarian-dashboard");
            Get.offAllNamed("/librarian-dashboard");
          } else if (["Reporter", "Cameraman", "Driver"].contains(role)) {
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

  // Google Sign-In Method
  Future<void> signInWithGoogle() async {
    try {
      isLoading(true);
      debugPrint("AuthController: Starting Google sign-in");
      
      if (_googleSignIn == null) {
        debugPrint("AuthController: Google Sign-In not available on this platform");
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
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      debugPrint("AuthController: Got access token: ${googleAuth.accessToken != null}");
      debugPrint("AuthController: Got ID token: ${googleAuth.idToken != null}");
      
      // Create a new credential
      debugPrint("AuthController: Creating Firebase credential");
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with the Google credential
      debugPrint("AuthController: Signing in to Firebase with Google credential");
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      debugPrint("AuthController: Firebase sign-in successful");
      
      if (userCredential.user == null) throw Exception("No user returned from Google sign in");
      
      // Check if this is a new user
      final bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      
      if (isNewUser) {
        // Create user document for new Google users
        String? fcmToken;
        if (!kIsWeb) {
          try {
            NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
              alert: true,
              badge: true,
              sound: true,
            );
            
            if (settings.authorizationStatus == AuthorizationStatus.authorized ||
                settings.authorizationStatus == AuthorizationStatus.provisional) {
              fcmToken = await FirebaseMessaging.instance.getToken();
            }
          } catch (e) {
            debugPrint("Error getting FCM Token during Google signup: $e");
          }
        }
        
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email ?? '',
          'fullName': userCredential.user!.displayName ?? '',
          'role': 'Reporter', // Default role for Google sign-up
          'fcmToken': fcmToken ?? "",
          'profileComplete': false,
          'photoUrl': userCredential.user!.photoURL ?? "",
          'createdAt': FieldValue.serverTimestamp(),
          'authProvider': 'google',
        });
        
        userRole.value = 'Reporter';
        fullName.value = userCredential.user!.displayName ?? '';
        profilePic.value = userCredential.user!.photoURL ?? '';
        
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
              debugPrint("AuthController: Waiting for user role to load (attempt ${attempts + 1})");
              await Future.delayed(const Duration(milliseconds: 200));
              attempts++;
            }
            debugPrint("AuthController: Role loaded: ${userRole.value}, navigating...");
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
        debugPrint("AuthController: Failed clearing user cache during logout: $e");
      }

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
        debugPrint("AuthController: Failed clearing user cache during signOut: $e");
      }

      // Presence offline and Firebase sign out in parallel
      await Future.wait([
        _handlePresence(false),
        _auth.signOut(),
      ]);

      // Give a tiny buffer to let listeners settle
      await Future.delayed(const Duration(milliseconds: 100));

      // Navigate to login and mark that it was from logout to bypass middleware loops
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
        url: 'https://task-app.firebaseapp.com/email-link-signin',
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
          } else if (role == "Librarian") {
            debugPrint("AuthController: Navigating to librarian-dashboard");
            Get.offAllNamed("/librarian-dashboard");
          } else if (["Reporter", "Cameraman", "Driver"].contains(role)) {
            debugPrint("AuthController: Navigating to home");
            Get.offAllNamed("/home");
          } else {
            debugPrint("AuthController: Navigating to login (fallback)");
            Get.offAllNamed("/login");
          }
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
    debugPrint('Inactivity check: ${now.difference(lastActivity.value).inMinutes} minutes since last activity');
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
}
