// core/bootstrap.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
import 'package:task/controllers/quarterly_transition_controller.dart';
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
const bool useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);
const String emulatorHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST', defaultValue: '192.168.1.7');

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
      statusBarColor: isDark ? Colors.grey[900] : Colors.white, // Background color
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark, // Icon color
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light, // For iOS
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

    // Load environment variables
    
    await dotenv.load(fileName: "assets/.env");
    

    // Initialize Firebase
    
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Automatically connect to emulator if flag is set
    if (useEmulator) {
      useFirebaseEmulator(emulatorHost);
    }
    
    
    // Initialize Firebase services (skip verification for faster boot)
    
    
    // Initialize User Cache Service early for better performance
    final userCacheService = UserCacheService();
    await userCacheService.initialize();
    Get.put(userCacheService, permanent: true);

    // Pre-fetch user data in background - don't block startup
    userCacheService.preFetchAllUsers().then((_) {
      debugPrint('🚀 BOOTSTRAP: User data pre-fetched in background');
    }).catchError((e) {
      debugPrint('⚠️ BOOTSTRAP: Background user pre-fetch failed: $e');
    });
    
    
    // Initialize Firebase Messaging Service (defer to background)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize Firebase Messaging in background to avoid blocking startup
    Future(() async {
      try {
        final firebaseMessagingService = FirebaseMessagingService();
        await firebaseMessagingService.initialize();
        Get.put(firebaseMessagingService, permanent: true);
        debugPrint('🚀 BOOTSTRAP: Firebase Messaging initialized in background');
      } catch (e) {
        debugPrint('⚠️ BOOTSTRAP: Firebase Messaging initialization failed: $e');
      }
    });
    

    // Initialize other services (defer heavy operations to background)

    final taskService = TaskService();
    // Initialize task service in background to avoid blocking
    taskService.initialize().then((_) {
      Get.put(taskService, permanent: true);
      debugPrint('🚀 BOOTSTRAP: TaskService initialized in background');
    }).catchError((e) {
      debugPrint('⚠️ BOOTSTRAP: TaskService initialization failed: $e');
      // Still register the service even if initialization fails
      Get.put(taskService, permanent: true);
    });
    

    // Initialize audio player (defer to background for faster startup)
    final audioPlayer = await Future(() async {
      try {
        return await _initializeAudioPlayer();
      } catch (e) {
        debugPrint('⚠️ BOOTSTRAP: Audio player initialization failed: $e');
        return AudioPlayer(); // Return default instance
      }
    });
    
    
    // Initialize CRITICAL services first (parallel)
    debugPrint("🚀 BOOTSTRAP: Initializing CRITICAL services in parallel");
    await Future.wait([
      _initializeService(() => AuthController(), 'AuthController'),
      _initializeService(() => ThemeController(), 'ThemeController'),
      _initializeService(() => QuarterlyTransitionService(), 'QuarterlyTransitionService'),
    ]);

    // Initialize ESSENTIAL services (parallel)
    debugPrint("🚀 BOOTSTRAP: Initializing ESSENTIAL services in parallel");
    await Future.wait([
      _initializeService<FirebaseStorageService>(() => FirebaseStorageService(), 'FirebaseStorageService'),
      _initializeService<ExportService>(() => ExportService(), 'ExportService'),
      _initializeService<ArchiveService>(() => ArchiveService(), 'ArchiveService'),
    ]);

    // Initialize OPTIONAL services (parallel, non-blocking)
    debugPrint("🚀 BOOTSTRAP: Initializing OPTIONAL services in parallel");
    await Future.wait([
      _initializeService<TaskAttachmentService>(() => TaskAttachmentService(), 'TaskAttachmentService'),
      _initializeService<PdfExportService>(() => PdfExportService(), 'PdfExportService', needsInitialization: true),
      _initializeService<VersionControlService>(() => VersionControlService(), 'VersionControlService'),
      _initializeService<DuplicateDetectionService>(() => DuplicateDetectionService(), 'DuplicateDetectionService'),
      _initializeService<CloudFunctionUserDeletionService>(() => CloudFunctionUserDeletionService(), 'UserDeletionService'),
      _initializeService<NewsService>(() => NewsService(), 'NewsService'),
      _initializeService<DailyTaskNotificationService>(() => DailyTaskNotificationService(), 'DailyTaskNotificationService'),
      _initializeService<AccessControlService>(() => AccessControlService(), 'AccessControlService'),
    ]);

    // Register the service by interface type as well
    Get.put<UserDeletionService>(Get.find<CloudFunctionUserDeletionService>(), permanent: true);
    
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

    // Initialize controllers that depend on services (parallel for critical ones)
    await Future.wait([
      // Put controllers directly since they're already instantiated
      Future(() => Get.put(AuthController(), permanent: true)),
      Future(() => Get.put(AppLockController(), permanent: true)),
      Future(() => Get.put(ThemeController(), permanent: true)),
      Future(() => Get.put(SettingsController(audioPlayer), permanent: true)),
      Future(() => Get.put(QuarterlyTransitionController(), permanent: true)),
      Future(() => Get.put(TaskController(), permanent: true)),
      Future(() => Get.put(UserController(Get.find<CloudFunctionUserDeletionService>()), permanent: true)),
      Future(() => Get.put(PresenceService(), permanent: true)),
      Future(() => Get.put(AdminController(), permanent: true)),
      Future(() => Get.put(ChatController(), permanent: true)),
    ]);
    
    // Initialize services that depend on controllers (parallel)
    await Future.wait([
      _initializeService<BulkOperationsService>(() => BulkOperationsService(), 'BulkOperationsService'),
      Future(() => Get.put(ManageUsersController(Get.find<CloudFunctionUserDeletionService>()), permanent: true)),
      Future(() => Get.put(NotificationController(), permanent: true)),
      Future(() => Get.put(PrivacyController(), permanent: true)),
      Future(() => Get.put(WallpaperController(), permanent: true)),
    ]);

    // Mark app as ready for snackbars BEFORE initializing controllers that might use them
    SnackbarUtils.markAppAsReady();

    // Initialize QuarterlyTransitionService (already initialized above)
    
    
    // Mark bootstrap as complete
    _isBootstrapComplete = true;
    final duration = DateTime.now().difference(_bootstrapStartTime!);
    debugPrint('🚀 BOOTSTRAP: App bootstrap completed in ${duration.inMilliseconds}ms');
    
    // Execute startup optimization in background (don't block app launch)
    StartupOptimizationService.to.executeStartup().then((_) {
      debugPrint('🚀 BOOTSTRAP: Startup optimization completed');
    }).catchError((e) {
      debugPrint('⚠️ BOOTSTRAP: Startup optimization failed: $e');
    });
    
    // Ensure widgets are properly initialized
    WidgetsFlutterBinding.ensureInitialized();
    
    // Run the app
    runApp(const MyApp());

    // Schedule Firebase verification to run in background after app starts
    Future.delayed(const Duration(seconds: 2), () async {
      await _verifyFirebaseServices();
    });


  } catch (e) {
    
    
    
    // Show error UI if bootstrap fails
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Failed to initialize app: $e'),
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
    
    final service = create();
    
    // Call initialize method if the service needs it
    if (needsInitialization && service is GetxService) {
      if (service.runtimeType.toString() == 'PdfExportService') {
        await (service as dynamic).initialize();
      }
    }
    
    // Put the service into GetX
    Get.put<T>(service, permanent: true);
    
  } catch (e) {
   
    rethrow;
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
      // Test if we can create a reference and perform basic operations
      try {
        await ref.getDownloadURL();
        debugPrint('✅ BOOTSTRAP: Firebase Storage verification passed');
      } catch (e) {
        // Expected to fail for non-existent file, but connection should work
        if (e.toString().contains('object-not-found') ||
            e.toString().contains('Object does not exist')) {
          debugPrint('✅ BOOTSTRAP: Firebase Storage verification passed (file not found but connection works)');
        } else {
          rethrow; // Re-throw if it's a different error, preserving stack trace
        }
      }
    } catch (e) {
      debugPrint('⚠️ BOOTSTRAP: Firebase Storage verification failed: $e');
      // Don't throw - storage might not be configured
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
  // ignore: empty_catches
  } catch (e) {
    
  }
  return player;
}


// Background Message Handler for Firebase Messaging
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if it hasn't been initialized yet
  if (!Firebase.apps.isNotEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
  
}