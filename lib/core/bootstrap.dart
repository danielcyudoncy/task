// core/bootstrap.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:task/service/export_service.dart';
import 'package:task/service/network_service.dart';
import 'package:task/service/connectivity_service.dart';
import 'package:task/service/error_handling_service.dart';
import 'package:task/service/loading_state_service.dart';
import 'package:task/service/offline_data_service.dart';
import 'package:task/service/startup_optimization_service.dart';
import 'package:task/utils/responsive_utils.dart';
import 'package:task/service/intelligent_cache_service.dart';
import 'package:task/service/cache_manager.dart';
import 'package:task/service/cached_task_service.dart';
import 'package:task/service/enhanced_notification_service.dart';
import '../my_app.dart';
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
import 'package:task/controllers/admin_controller.dart';
import 'package:task/service/quarterly_transition_service.dart';
import 'package:task/firebase_options.dart';

import 'package:task/service/cloud_function_user_deletion_service.dart';
import 'package:task/service/user_deletion_service.dart';
import 'package:task/service/news_service.dart';
import 'package:task/service/presence_service.dart';
import 'package:task/service/firebase_storage_service.dart';
import 'package:task/service/firebase_service.dart' show useFirebaseEmulator;
import 'package:task/service/archive_service.dart';
import 'package:task/utils/constants/app_constants.dart';
import 'package:task/service/task_attachment_service.dart';
import 'package:task/service/bulk_operations_service.dart';
import 'package:task/service/version_control_service.dart';
import 'package:task/service/pdf_export_service.dart';
import 'package:task/service/duplicate_detection_service.dart';
import 'package:task/service/access_control_service.dart';
import 'package:task/service/task_service.dart';
import 'package:task/service/firebase_messaging_service.dart';
import 'package:task/service/daily_task_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:task/utils/snackbar_utils.dart';
import 'package:task/service/user_cache_service.dart';
import 'package:task/service/biometric_service.dart';
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
Duration? get bootstrapDuration => _isBootstrapComplete && _bootstrapStartTime != null
    ? DateTime.now().difference(_bootstrapStartTime!)
    : null;

void _updateStatusBarColor() {
  final themeController = Get.find<ThemeController>();
  final isDark = themeController.isCurrentlyDark;

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor:
          isDark ? Colors.grey[900] : Colors.white, // Background color
      statusBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark, // Icon color
      statusBarBrightness:
          isDark ? Brightness.dark : Brightness.light, // For iOS
    ),
  );
}

Future<void> bootstrapApp() async {
  _bootstrapStartTime = DateTime.now();
  debugPrint('🚀 BOOTSTRAP: Starting app bootstrap at ${_bootstrapStartTime!}');

  try {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize ThemeController first
    Get.put(ThemeController(), permanent: true);

    // Configure database factory (web uses FFI web)
    configureDbFactory();

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Set initial status bar color based on current theme
    _updateStatusBarColor();

    // Listen to theme changes to update status bar color
    final themeController = Get.find<ThemeController>();
    ever(themeController.isDarkMode, (_) {
      _updateStatusBarColor();
    });

    // Initialize error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
    };

    // Set uncaught error handler
    PlatformDispatcher.instance.onError = (error, stack) {
      return true;
    };

    // Load environment variables (can be done in parallel with other operations)
    await dotenv.load(fileName: "assets/.env");

    // Initialize Firebase

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize Crashlytics
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Automatically connect to emulator if flag is set
    if (useEmulator) {
      useFirebaseEmulator(emulatorHost);
    }

    // Initialize CRITICAL services only (parallel for speed)
    debugPrint("🚀 BOOTSTRAP: Initializing CRITICAL services in parallel");
    await Future.wait([
      _initializeService(() => ThemeController(), 'ThemeController'),
      _initializeService(() => QuarterlyTransitionService(), 'QuarterlyTransitionService'),
    ]);

    // Initialize AuthController last to avoid race conditions with Firebase services
    debugPrint("🚀 BOOTSTRAP: Initializing AuthController");
    await _initializeService(() => AuthController(), 'AuthController');

    // Wait a bit for auth state to stabilize before proceeding
    await Future.delayed(const Duration(milliseconds: 200));

    // Initialize User Cache Service early for better performance (but don't pre-fetch yet)
    final userCacheService = UserCacheService();
    await userCacheService.initialize();
    Get.put(userCacheService, permanent: true);

    // Defer heavy operations to background with microtask for better performance
    Future.microtask(() async {
      try {
        await _verifyFirebaseServices();
        debugPrint('🚀 BOOTSTRAP: Firebase verification completed in background');
      } catch (e) {
        debugPrint('⚠️ BOOTSTRAP: Background Firebase verification failed: $e');
      }
    });

    // Defer user data pre-fetching to background (don't block startup)
    Future(() async {
      try {
        await userCacheService.preFetchAllUsers();
        debugPrint('🚀 BOOTSTRAP: User data pre-fetched in background');
      } catch (e) {
        debugPrint('⚠️ BOOTSTRAP: Background user pre-fetch failed: $e');
      }
    });

    // Initialize Firebase Messaging in background (don't block startup)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    Future.microtask(() async {
      try {
        final firebaseMessagingService = FirebaseMessagingService();
        await firebaseMessagingService.initialize();
        Get.put(firebaseMessagingService, permanent: true);
        debugPrint('🚀 BOOTSTRAP: Firebase Messaging initialized in background');
      } catch (e) {
        debugPrint('⚠️ BOOTSTRAP: Firebase Messaging initialization failed: $e');
      }
    });

    // Initialize TaskService in background using microtask for even faster startup
    Future.microtask(() async {
      try {
        final taskService = TaskService();
        await taskService.initialize();
        Get.put(taskService, permanent: true);
        debugPrint('🚀 BOOTSTRAP: TaskService initialized in background');
      } catch (e) {
        debugPrint('⚠️ BOOTSTRAP: TaskService initialization failed: $e');
        Get.put(TaskService(), permanent: true); // Still register even if init fails
      }
    });

    // Initialize audio player (can run in parallel)
    final audioPlayer = await _initializeAudioPlayer();

    // Initialize CRITICAL services first (parallel but limited)
    debugPrint("🚀 BOOTSTRAP: Initializing CRITICAL services in parallel");
    await Future.wait([
      _initializeService(() => ThemeController(), 'ThemeController'),
      _initializeService(() => QuarterlyTransitionService(), 'QuarterlyTransitionService'),
    ]);

    // Initialize AuthController separately to avoid race conditions
    await _initializeService(() => AuthController(), 'AuthController');

    // Initialize ESSENTIAL services (parallel but limited to avoid blocking)
    debugPrint("🚀 BOOTSTRAP: Initializing ESSENTIAL services in parallel");
    await Future.wait([
      _initializeService<FirebaseStorageService>(() => FirebaseStorageService(), 'FirebaseStorageService'),
      _initializeService<ExportService>(() => ExportService(), 'ExportService'),
    ]);

    // Initialize ArchiveService separately to avoid blocking
    await _initializeService<ArchiveService>(() => ArchiveService(), 'ArchiveService');

    // Initialize CloudFunctionUserDeletionService first (needed by other services)
    debugPrint("🚀 BOOTSTRAP: Initializing CloudFunctionUserDeletionService");
    await _initializeService<CloudFunctionUserDeletionService>(() => CloudFunctionUserDeletionService(), 'CloudFunctionUserDeletionService');

    // Register the service by interface type as well
    Get.put<UserDeletionService>(Get.find<CloudFunctionUserDeletionService>(), permanent: true);

    // Initialize OPTIONAL services in background (don't block main thread)
    debugPrint("🚀 BOOTSTRAP: Initializing OPTIONAL services in background");
    _initializeOptionalServicesInBackground();

    // Initialize new architecture services (parallel)
    await Future.wait([
      _initializeService<StartupOptimizationService>(() => StartupOptimizationService(), 'StartupOptimizationService'),
      _initializeService<ResponsiveController>(() => ResponsiveController(), 'ResponsiveController'),
      _initializeService<IntelligentCacheService>(() => IntelligentCacheService(), 'IntelligentCacheService'),
      _initializeService<CacheManager>(() => CacheManager(), 'CacheManager'),
      _initializeService<CachedTaskService>(() => CachedTaskService(), 'CachedTaskService'),
      _initializeService<EnhancedNotificationService>(() => EnhancedNotificationService(), 'EnhancedNotificationService'),
      _initializeService<NetworkService>(() => NetworkService(), 'NetworkService'),
      _initializeService<ConnectivityService>(() => ConnectivityService(), 'ConnectivityService'),
      _initializeService<ErrorHandlingService>(() => ErrorHandlingService(), 'ErrorHandlingService'),
      _initializeService<LoadingStateService>(() => LoadingStateService(), 'LoadingStateService'),
      _initializeService<OfflineDataService>(() => OfflineDataService(), 'OfflineDataService'),
    ]);

    // Initialize BiometricService early for app lock functionality
    await _initializeService<BiometricService>(() => BiometricService(), 'BiometricService');

    // Initialize controllers that depend on services (skip already initialized ones)
    Get.put(AppLockController(), permanent: true);
    Get.put(SettingsController(audioPlayer), permanent: true);
    Get.put(TaskController(), permanent: true);
    Get.put(UserController(Get.find<CloudFunctionUserDeletionService>()), permanent: true);
    Get.put(PresenceService(), permanent: true);
    Get.put(AdminController(), permanent: true);
    Get.put(ChatController(), permanent: true);

    // Initialize services that depend on controllers
    await _initializeService<BulkOperationsService>(
      () => BulkOperationsService(),
      'BulkOperationsService',
    );

    Get.put(ManageUsersController(Get.find<CloudFunctionUserDeletionService>()),
        permanent: true);

    // Mark app as ready for snackbars BEFORE initializing controllers that might use them
    SnackbarUtils.markAppAsReady();

    Get.put(NotificationController(), permanent: true);

    Get.put(PrivacyController(), permanent: true);

    Get.put(WallpaperController(), permanent: true);

    // QuarterlyTransitionService already initialized at line 194

    // Mark bootstrap as complete
    _isBootstrapComplete = true;
    final bootstrapEndTime = DateTime.now();
    final totalBootTime = bootstrapEndTime.difference(_bootstrapStartTime!);
    debugPrint('🚀 BOOTSTRAP: App bootstrap completed in ${totalBootTime.inMilliseconds}ms');

    // Execute startup optimization in background (don't block app launch)
    Future(() async {
      try {
        await StartupOptimizationService.to.executeStartup();
        debugPrint('🚀 BOOTSTRAP: Startup optimization completed in background');
      } catch (e) {
        debugPrint('⚠️ BOOTSTRAP: Startup optimization failed: $e');
      }
    });

    // Run the app
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('❌ BOOTSTRAP: Critical error during app initialization: $e');
    debugPrint('Stack trace: $stackTrace');

    // Log error to Crashlytics if available
    try {
      if (Firebase.apps.isNotEmpty) {
        FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Bootstrap failed');
      }
    } catch (crashlyticsError) {
      debugPrint('Failed to log bootstrap error to Crashlytics: $crashlyticsError');
    }

    // Show error UI if bootstrap fails
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
                const Text(
                  'Failed to initialize app',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: ${e.toString()}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Attempt to restart the app
                    runApp(const MaterialApp(
                      home: Scaffold(
                        body: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Restarting app...'),
                            ],
                          ),
                        ),
                      ),
                    ));

                    // Restart bootstrap after a delay
                    Future.delayed(const Duration(seconds: 2), () {
                      bootstrapApp();
                    });
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
}

Future<void> _initializeService<T>(
  T Function() create,
  String serviceName, {
  bool needsInitialization = false,
}) async {
  try {
    debugPrint("🚀 BOOTSTRAP: Initializing service: $serviceName");

    final service = create();

    // Call initialize method if the service needs it
    if (needsInitialization && service is GetxService) {
      try {
        if (service.runtimeType.toString() == 'PdfExportService') {
          await (service as dynamic).initialize().timeout(const Duration(seconds: 10));
        }
      } catch (initError) {
        debugPrint('⚠️ BOOTSTRAP: Service $serviceName initialization failed: $initError');
        // Continue with registration even if initialization fails
      }
    }

    // Put the service into GetX
    Get.put<T>(service, permanent: true);

    debugPrint("✅ BOOTSTRAP: Service $serviceName initialized successfully");
  } catch (e) {
    debugPrint('❌ BOOTSTRAP: Failed to initialize service $serviceName: $e');

    // For critical services, we might want to throw, but for optional services, continue
    if (serviceName.contains('AuthController') ||
        serviceName.contains('ThemeController') ||
        serviceName.contains('Firebase')) {
      debugPrint('🚨 BOOTSTRAP: Critical service $serviceName failed, rethrowing');
      rethrow;
    } else {
      debugPrint('⚠️ BOOTSTRAP: Non-critical service $serviceName failed, continuing');
      // Don't rethrow for non-critical services
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

    // Verify Firestore is accessible (if available)
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('_health_check').limit(1).get();
      debugPrint('✅ BOOTSTRAP: Firebase Firestore verification passed');
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
             debugPrint('✅ BOOTSTRAP: Firebase Storage verification passed (file not found but connection works)');
           } else if (e.toString().contains('unauthorized') ||
                      e.toString().contains('not authenticated')) {
             debugPrint('⚠️ BOOTSTRAP: Firebase Storage verification skipped - user not authenticated');
           } else {
             rethrow; // Re-throw if it's a different error, preserving stack trace
           }
         }
       } else {
         debugPrint('⚠️ BOOTSTRAP: Firebase Storage verification skipped - no user authenticated');
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

// Removed duplicate _verifyFirebaseServices function - keeping the comprehensive one above

/// Initialize optional services in background to avoid blocking main thread
void _initializeOptionalServicesInBackground() {
  Future.microtask(() async {
    try {
      debugPrint("🚀 BOOTSTRAP: Starting background initialization of optional services");

      // Initialize services in smaller batches to avoid overwhelming the system
      await Future.wait([
        _initializeService<TaskAttachmentService>(() => TaskAttachmentService(), 'TaskAttachmentService'),
        _initializeService<PdfExportService>(() => PdfExportService(), 'PdfExportService', needsInitialization: true),
      ]);

      await Future.delayed(const Duration(milliseconds: 100)); // Small pause

      await Future.wait([
        _initializeService<VersionControlService>(() => VersionControlService(), 'VersionControlService'),
        _initializeService<DuplicateDetectionService>(() => DuplicateDetectionService(), 'DuplicateDetectionService'),
      ]);

      await Future.delayed(const Duration(milliseconds: 100)); // Small pause

      await Future.wait([
        _initializeService<NewsService>(() => NewsService(), 'NewsService'),
      ]);

      await Future.delayed(const Duration(milliseconds: 100)); // Small pause

      await Future.wait([
        _initializeService<DailyTaskNotificationService>(() => DailyTaskNotificationService(), 'DailyTaskNotificationService'),
        _initializeService<AccessControlService>(() => AccessControlService(), 'AccessControlService'),
      ]);

      debugPrint("🚀 BOOTSTRAP: Background initialization of optional services completed");
    } catch (e) {
      debugPrint("⚠️ BOOTSTRAP: Background initialization of optional services failed: $e");
    }
  });
}

// Background Message Handler for Firebase Messaging
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Only initialize Firebase if it hasn't been initialized yet
  // This prevents duplicate initialization issues
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase background initialization failed: $e');
      // Continue with message handling even if Firebase init fails
    }
  }
}
