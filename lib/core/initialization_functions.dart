// core/initialization_functions.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/theme_controller.dart';
import 'package:task/firebase_options.dart';
import 'package:task/service/firebase_service.dart';
import 'package:task/service/user_cache_service.dart';
import 'package:task/utils/constants/app_constants.dart';

const bool useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);

// Initialize Firebase
Future<void> initializeFirebase() async {
  try {
    debugPrint('🚀 BOOTSTRAP: Initializing Firebase');
    
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    if (useEmulator) {
      await Future.microtask(() => useFirebaseEmulator(FirebaseConstants.emulatorHost));
    }
    
    // Initialize analytics (no auth required)
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
    
    debugPrint('✅ BOOTSTRAP: Firebase initialized');
  } catch (e, stackTrace) {
    debugPrint('❌ BOOTSTRAP: Firebase initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
  }
}

// Initialize Theme
Future<void> initializeTheme() async {
  try {
    debugPrint('🚀 BOOTSTRAP: Initializing Theme');
    final themeController = ThemeController();
    Get.put(themeController, permanent: true);
    themeController.onInit();
    debugPrint('✅ BOOTSTRAP: Theme initialized');
  } catch (e) {
    debugPrint('❌ BOOTSTRAP: Theme initialization failed: $e');
    rethrow;
  }
}

// Initialize Authentication
Future<void> initializeAuth() async {
  try {
    debugPrint('🚀 BOOTSTRAP: Initializing Auth');
    final auth = FirebaseAuth.instance;
    await auth.authStateChanges().first; // Wait for initial auth state
    debugPrint('✅ BOOTSTRAP: Auth initialized');
  } catch (e) {
    debugPrint('❌ BOOTSTRAP: Auth initialization failed: $e');
    // Don't rethrow auth errors - allow anonymous access
  }
}

// Load User Cache
Future<void> initializeUserCache() async {
  try {
    debugPrint('🚀 BOOTSTRAP: Initializing User Cache');
    final users = await FirebaseFirestore.instance
        .collection('users')
        .limit(50) // Load initial batch
        .get();
        
    for (var doc in users.docs) {
      final service = UserCacheService();
      await service.initialize();
      await service.getUserName(doc.id);
    }
    
    debugPrint('✅ BOOTSTRAP: Initial User Cache loaded');
  } catch (e) {
    debugPrint('❌ BOOTSTRAP: User Cache initialization failed: $e');
    // Don't rethrow - cache can be built gradually
  }
}

// Background service initialization
Future<void> initializeBackgroundServices() async {
  try {
    debugPrint('🚀 BOOTSTRAP: Initializing background services');
    
    // Initialize services in parallel batches
    await Future.wait([
      _initializeNotifications(),
      _initializeAnalytics(),
      _initializeStorage(),
    ]);
    
    debugPrint('✅ BOOTSTRAP: Background services initialized');
  } catch (e) {
    debugPrint('❌ BOOTSTRAP: Background services initialization failed: $e');
    // Don't rethrow background service errors
  }
}

Future<void> _initializeNotifications() async {
  try {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    await messaging.getToken();
  } catch (e) {
    debugPrint('⚠️ Notification initialization failed: $e');
  }
}

Future<void> _initializeAnalytics() async {
  try {
    await Firebase.initializeApp();
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  } catch (e) {
    debugPrint('⚠️ Analytics initialization failed: $e');
  }
}

Future<void> _initializeStorage() async {
  try {
    await FirebaseStorage.instance.ref().listAll();
  } catch (e) {
    debugPrint('⚠️ Storage initialization failed: $e');
  }
}