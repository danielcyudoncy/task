// core/bootstrap.dart

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:task/controllers/admin_controller.dart';
import 'package:task/controllers/app_lock_controller.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/controllers/chat_controller.dart';
import 'package:task/controllers/manage_users_controller.dart';
import 'package:task/controllers/notification_controller.dart';
import 'package:task/controllers/privacy_controller.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:task/controllers/theme_controller.dart';
import 'package:task/controllers/user_controller.dart';
import 'package:task/controllers/wallpaper_controller.dart';
import 'package:task/firebase_options.dart';
import 'package:task/service/access_control_service.dart';
import 'package:task/service/archive_service.dart';
import 'package:task/service/biometric_service.dart';
import 'package:task/service/bulk_operations_service.dart';
import 'package:task/service/cache_manager.dart';
import 'package:task/service/cached_task_service.dart';
import 'package:task/service/cloud_function_user_deletion_service.dart';
import 'package:task/service/connectivity_service.dart';
import 'package:task/service/daily_task_notification_service.dart';
import 'package:task/service/duplicate_detection_service.dart';
import 'package:task/service/enhanced_notification_service.dart';
import 'package:task/service/error_handling_service.dart';
import 'package:task/service/export_service.dart';
import 'package:task/service/firebase_messaging_service.dart';
import 'package:task/service/firebase_service.dart' show useFirebaseEmulator;
import 'package:task/service/firebase_storage_service.dart';
import 'package:task/service/intelligent_cache_service.dart';
import 'package:task/service/loading_state_service.dart';
import 'package:task/service/network_service.dart';
import 'package:task/service/news_service.dart';
import 'package:task/service/offline_data_service.dart';
import 'package:task/service/pdf_export_service.dart';
import 'package:task/service/presence_service.dart';
import 'package:task/service/quarterly_transition_service.dart';
import 'package:task/service/startup_optimization_service.dart';
import 'package:task/service/task_attachment_service.dart';
import 'package:task/service/task_service.dart';
import 'package:task/service/user_cache_service.dart';
import 'package:task/service/user_deletion_service.dart';
import 'package:task/service/version_control_service.dart';
import 'package:task/utils/constants/app_constants.dart';
import 'package:task/utils/snackbar_utils.dart';

import '../my_app.dart';
import 'db_factory_stub.dart' if (dart.library.html) 'db_factory_web.dart';

// --- Emulator/Production Switch ---
const bool useEmulator =
    bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);
const String emulatorHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST',
    defaultValue: FirebaseConstants.emulatorHost);

// Global flag to track bootstrap state
bool _isBootstrapComplete = false;
bool get isBootstrapComplete => _isBootstrapComplete;

// Performance monitoring
DateTime? _bootstrapStartTime;
final Map<String, Duration> _serviceInitializationTimes = {};

void _recordServiceInitialization(String serviceName, Duration duration) {
  _serviceInitializationTimes[serviceName] = duration;
  debugPrint(
      '⏱️ PERFORMANCE: $serviceName initialized in ${duration.inMilliseconds}ms');
}

void printPerformanceReport() {
  if (_bootstrapStartTime == null) return;

  final totalDuration = DateTime.now().difference(_bootstrapStartTime!);
  debugPrint('📊 PERFORMANCE REPORT:');
  debugPrint('   Total bootstrap time: ${totalDuration.inMilliseconds}ms');
  debugPrint('   Services initialized: ${_serviceInitializationTimes.length}');

  final sortedServices = _serviceInitializationTimes.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  for (var entry in sortedServices.take(5)) {
    debugPrint('   ${entry.key}: ${entry.value.inMilliseconds}ms');
  }
}

void _updateStatusBarColor() {
  final themeController = Get.find<ThemeController>();
  final isDark = themeController.isCurrentlyDark;

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: isDark ? Colors.grey[900] : Colors.white,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    ),
  );
}

Future<void> bootstrapApp() async {
  _bootstrapStartTime = DateTime.now();
  debugPrint('🚀 BOOTSTRAP: Starting app bootstrap at $_bootstrapStartTime');

  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    configureDbFactory();
    await dotenv.load(fileName: "assets/.env");

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await _initializeCoreServices();
    _setupErrorHandling();

    runApp(const MyApp());

    FlutterNativeSplash.remove();

    _updateStatusBarColor();
    final themeController = Get.find<ThemeController>();
    ever(themeController.isDarkMode, (_) => _updateStatusBarColor());

    _initializeServicesInBackground();

    _isBootstrapComplete = true;
    final totalBootTime = DateTime.now().difference(_bootstrapStartTime!);
    debugPrint(
        '🚀 BOOTSTRAP: App bootstrap completed in ${totalBootTime.inMilliseconds}ms');

    Future.delayed(const Duration(seconds: 2), printPerformanceReport);
  } catch (e, stackTrace) {
    debugPrint('❌ BOOTSTRAP: Critical error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    _showErrorUI(e);
  }
}

Future<void> _initializeCoreServices() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Firebase App Check with proper configuration
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          AndroidProvider.playIntegrity, // Use .playIntegrity for production
      appleProvider:
          AppleProvider.deviceCheck, // Use .deviceCheck for production
    );
    debugPrint('✅ BOOTSTRAP: Firebase App Check activated successfully');
  } catch (e) {
    debugPrint('⚠️ BOOTSTRAP: Firebase App Check activation failed: $e');
    debugPrint(
        '⚠️ BOOTSTRAP: Continuing without App Check - this may reduce security but allows app to function');
    // Continue without App Check to prevent app crashes
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (useEmulator) {
    Future.microtask(() => useFirebaseEmulator(emulatorHost));
  }

  await _initializeService(() => ThemeController(), 'ThemeController');
  await _initializeService(() => AuthController(), 'AuthController');

  final userCacheService = UserCacheService();
  await userCacheService.initialize();
  Get.put(userCacheService, permanent: true);

  final audioPlayer = await _initializeAudioPlayer();
  Get.put(SettingsController(audioPlayer), permanent: true);

  // Initialize BiometricService before AppLockController
  await _initializeService(() => BiometricService(), 'BiometricService');
  Get.put(AppLockController(), permanent: true);

  // Setup notification navigation
  _setupNotificationNavigation();

  SnackbarUtils.markAppAsReady();
}

void _setupNotificationNavigation() {
  // Handle notification tap when app is in background but opened
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint("bootstrap: onMessageOpenedApp: ${message.data}");
    _handleNotificationNavigation(message);
  });

  // Handle notification tap when app is terminated and opened
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      debugPrint("bootstrap: getInitialMessage: ${message.data}");
      _handleNotificationNavigation(message);
    }
  });
}

void _handleNotificationNavigation(RemoteMessage message) {
  final data = message.data;
  final type = data['type'];

  if (type == 'chat_message') {
    final conversationId = data['conversationId'];
    if (conversationId != null) {
      // Delay navigation slightly to ensure app is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.toNamed('/user-chat-list',
            arguments: {'conversationId': conversationId});
      });
    }
  } else if (type == 'task_assigned') {
    final taskId = data['taskId'];
    if (taskId != null) {
      // Delay navigation slightly to ensure app is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        Get.toNamed('/tasks', arguments: {'taskId': taskId});
      });
    }
  }
}

void _setupErrorHandling() {
  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

void _initializeServicesInBackground() {
  Future.microtask(() async {
    await _verifyFirebaseServices();

    final coreServices = [
      _initializeService(
          () => QuarterlyTransitionService(), 'QuarterlyTransitionService'),
      _initializeService(
          () => FirebaseMessagingService(), 'FirebaseMessagingService',
          needsInitialization: true),
      _initializeService(() => TaskService(), 'TaskService'),
      _initializeService(
          () => FirebaseStorageService(), 'FirebaseStorageService'),
      _initializeService(() => ExportService(), 'ExportService'),
      _initializeService(() => ArchiveService(), 'ArchiveService'),
      // BiometricService is now initialized above
      _initializeService(
          () => TaskAttachmentService(), 'TaskAttachmentService'),
    ];

    // Initialize PdfExportService first, as it's required by BulkOperationsService
    await _initializeService(() => PdfExportService(), 'PdfExportService',
        needsInitialization: true);
    await _initializeService(
        () => VersionControlService(), 'VersionControlService');

    final remainingServices = [
      _initializeService(
          () => DuplicateDetectionService(), 'DuplicateDetectionService'),
      _initializeService(
          () => DailyTaskNotificationService(), 'DailyTaskNotificationService'),
      _initializeService(() => AccessControlService(), 'AccessControlService'),
      _initializeService(
          () => StartupOptimizationService(), 'StartupOptimizationService'),
      _initializeService(
          () => IntelligentCacheService(), 'IntelligentCacheService'),
      _initializeService(() => CacheManager(), 'CacheManager'),
      _initializeService(() => NetworkService(), 'NetworkService'),
      _initializeService(() => ConnectivityService(), 'ConnectivityService'),
      _initializeService(() => ErrorHandlingService(), 'ErrorHandlingService'),
      _initializeService(() => LoadingStateService(), 'LoadingStateService'),
      _initializeService(() => OfflineDataService(), 'OfflineDataService'),
      _initializeService(() => CachedTaskService(), 'CachedTaskService'),
      _initializeService(
          () => EnhancedNotificationService(), 'EnhancedNotificationService'),
    ];

    await Future.wait(coreServices);
    await Future.wait(remainingServices);

    // Initialize CloudFunctionUserDeletionService before any services that depend on it
    await _initializeService(() => CloudFunctionUserDeletionService(),
        'CloudFunctionUserDeletionService');

    Get.put<UserDeletionService>(Get.find<CloudFunctionUserDeletionService>(),
        permanent: true);

    // Initialize controllers first before services that depend on them
    final controllers = [
      _initializeService(() => TaskController(), 'TaskController'),
      _initializeService(
          () => UserController(Get.find<CloudFunctionUserDeletionService>()),
          'UserController'),
      _initializeService(() => PresenceService(), 'PresenceService'),
      _initializeService(() => AdminController(), 'AdminController'),
      _initializeService(() => ChatController(), 'ChatController'),
      _initializeService(
          () => ManageUsersController(
              Get.find<CloudFunctionUserDeletionService>()),
          'ManageUsersController'),
      _initializeService(
          () => NotificationController(), 'NotificationController'),
      _initializeService(() => PrivacyController(), 'PrivacyController'),
      _initializeService(() => WallpaperController(), 'WallpaperController'),
    ];
    await Future.wait(controllers);

    // Initialize BulkOperationsService after controllers are ready
    final finalServices = [
      _initializeService(
          () => BulkOperationsService(), 'BulkOperationsService'),
    ];
    await Future.wait(finalServices);

    if (FirebaseAuth.instance.currentUser != null) {
      await _initializeService(() => NewsService(), 'NewsService');
    } else {
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null && !Get.isRegistered<NewsService>()) {
          _initializeService(() => NewsService(), 'NewsService');
        }
      });
    }

    if (Get.isRegistered<StartupOptimizationService>()) {
      StartupOptimizationService.to.executeStartup();
    }
  });
}

Future<void> _initializeService<T>(
  T Function() create,
  String serviceName, {
  bool needsInitialization = false,
}) async {
  final startTime = DateTime.now();
  try {
    final service = create();
    if (needsInitialization && service is GetxService) {
      if (service.runtimeType.toString() == 'PdfExportService') {
        await (service as dynamic)
            .initialize()
            .timeout(const Duration(seconds: 10));
      } else if (service.runtimeType.toString() == 'FirebaseMessagingService') {
        await (service as dynamic).initialize();
      }
    }
    Get.put<T>(service, permanent: true);
    final duration = DateTime.now().difference(startTime);
    _recordServiceInitialization(serviceName, duration);
  } catch (e) {
    debugPrint('❌ BOOTSTRAP: Failed to initialize service $serviceName: $e');
    if (serviceName.contains('AuthController') ||
        serviceName.contains('ThemeController')) {
      debugPrint(
          '🚨 BOOTSTRAP: Critical service $serviceName failed, rethrowing');
      rethrow;
    }
  }
}

void _showErrorUI(dynamic error) {
  runApp(MaterialApp(
    home: Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Failed to initialize app',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Error: ${error.toString()}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  runApp(const MaterialApp(
                      home: Scaffold(
                          body: Center(child: CircularProgressIndicator()))));
                  Future.delayed(const Duration(seconds: 2), bootstrapApp);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    ),
  ));
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase background initialization failed: $e');
    }
  }
}

/// Verifies that Firebase services are working properly
Future<void> _verifyFirebaseServices() async {
  try {
    debugPrint('🔥 BOOTSTRAP: Starting Firebase services verification');

    // Verify Firebase Core is initialized
    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase Core is not initialized');
    }

    // Verify Firebase Auth is accessible (if user is authenticated)
    try {
      final auth = FirebaseAuth.instance;
      await auth.currentUser?.reload(); // Test if auth is working
      debugPrint('✅ BOOTSTRAP: Firebase Auth verification passed');
    } catch (e) {
      debugPrint('⚠️ BOOTSTRAP: Firebase Auth verification failed: $e');
      // Don't throw - auth might not be configured or user might not be logged in
    }

    // Verify Firestore is accessible (if user is authenticated)
    try {
      final firestore = FirebaseFirestore.instance;
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await firestore.collection('_health_check').limit(1).get();
        debugPrint('✅ BOOTSTRAP: Firebase Firestore verification passed');
      } else {
        debugPrint(
            '⚠️ BOOTSTRAP: Firebase Firestore verification skipped - no user authenticated');
      }
    } catch (e) {
      debugPrint('⚠️ BOOTSTRAP: Firebase Firestore verification failed: $e');
      // Don't throw - firestore might not be configured or accessible
    }

    // Verify Firebase Storage is accessible (if available)
    try {
      final storage = FirebaseStorage.instance;
      final ref = storage.ref().child('_health_check');

      // Check if user is authenticated before testing storage
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Test if we can create a reference and perform basic operations
        try {
          await ref.getDownloadURL();
          debugPrint('✅ BOOTSTRAP: Firebase Storage verification passed');
        } catch (e) {
          // Expected to fail for non-existent file, but connection should work
          if (e.toString().contains('object-not-found') ||
              e.toString().contains('Object does not exist')) {
            debugPrint(
                '✅ BOOTSTRAP: Firebase Storage verification passed (file not found but connection works)');
          } else if (e.toString().contains('unauthorized') ||
              e.toString().contains('not authenticated')) {
            debugPrint(
                '⚠️ BOOTSTRAP: Firebase Storage verification skipped - user not authenticated');
          } else {
            rethrow; // Re-throw if it's a different error, preserving stack trace
          }
        }
      } else {
        debugPrint(
            '⚠️ BOOTSTRAP: Firebase Storage verification skipped - no user authenticated');
      }
    } catch (e) {
      debugPrint('⚠️ BOOTSTRAP: Firebase Storage verification failed: $e');
      // Don't throw - storage might not be configured or user might not be authenticated
    }

    // Verify Firebase Messaging is working (if available)
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.getToken();
      debugPrint('✅ BOOTSTRAP: Firebase Messaging verification passed');
    } catch (e) {
      debugPrint('⚠️ BOOTSTRAP: Firebase Messaging verification failed: $e');
      // Don't throw - messaging might not be configured or permissions denied
    }

    debugPrint('🔥 BOOTSTRAP: Firebase services verification completed');
  } catch (e) {
    debugPrint('❌ BOOTSTRAP: Firebase services verification failed: $e');
    // Don't rethrow - we don't want verification failures to crash the app
  }
}

Future<AudioPlayer> _initializeAudioPlayer() async {
  final player = AudioPlayer();
  try {
    await player.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: false,
          audioMode: AndroidAudioMode.normal,
        ),
        // --- CORRECTED: Safest configuration for playback ---
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
      ),
    );
  } catch (e) {
    debugPrint('Audio player initialization failed: $e');
    // Continue with app initialization even if audio fails
  }
  return player;
}
