// core/bootstrap.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
// Removed Isar imports - using SQLite now
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

// --- Ensure all your controllers and services are imported ---
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
import 'db_factory_stub.dart' if (dart.library.html) 'db_factory_web.dart';

// --- Emulator/Production Switch ---
const bool useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);
const String emulatorHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST', defaultValue: '192.168.1.7');

// Global flag to track bootstrap state
bool _isBootstrapComplete = false;
bool get isBootstrapComplete => _isBootstrapComplete;

Future<void> bootstrapApp() async {
  try {
    
    
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();
    // Configure database factory (web uses FFI web)
    configureDbFactory();
    
    
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
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
    
    
    // Initialize Firebase services
    
    await _verifyFirebaseServices();
    
    
    // Initialize User Cache Service early for better performance
    
    final userCacheService = UserCacheService();
    await userCacheService.initialize();
    Get.put(userCacheService, permanent: true);
    
    // Pre-fetch all user names and avatars for immediate display
    
    try {
      await userCacheService.preFetchAllUsers();
      debugPrint('🚀 BOOTSTRAP: Pre-fetched user data for immediate display');
    } catch (e) {
      debugPrint('⚠️ BOOTSTRAP: Failed to pre-fetch user data: $e');
      // Continue bootstrap even if pre-fetch fails
    }
    
    
    // Initialize Firebase Messaging Service
    
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    final firebaseMessagingService = FirebaseMessagingService();
    await firebaseMessagingService.initialize();
    Get.put(firebaseMessagingService, permanent: true);
    

    // Initialize other services
    
    final taskService = TaskService();
    await taskService.initialize();
    Get.put(taskService, permanent: true);
    

    // Initialize audio player
    
    final audioPlayer = await _initializeAudioPlayer();
    
    
    // Initialize services
    debugPrint("🚀 BOOTSTRAP: Initializing services");
    await _initializeService(() => AuthController(), 'AuthController');
    await _initializeService(() => ThemeController(), 'ThemeController');
    await _initializeService(() => QuarterlyTransitionService(), 'QuarterlyTransitionService');
    
    // Initialize other services with proper error handling
    await _initializeService<FirebaseStorageService>(
      () => FirebaseStorageService(),
      'FirebaseStorageService',
    );
    
    await _initializeService<ExportService>(
      () => ExportService(),
      'ExportService',
    );
    
    await _initializeService<ArchiveService>(
      () => ArchiveService(),
      'ArchiveService',
    );
    
    await _initializeService<TaskAttachmentService>(
      () => TaskAttachmentService(),
      'TaskAttachmentService',
    );
    
    await _initializeService<PdfExportService>(
      () => PdfExportService(),
      'PdfExportService',
      needsInitialization: true,
    );
    
    await _initializeService<VersionControlService>(
      () => VersionControlService(),
      'VersionControlService',
    );
    
    await _initializeService<DuplicateDetectionService>(
      () => DuplicateDetectionService(),
      'DuplicateDetectionService',
    );
    
    await _initializeService<CloudFunctionUserDeletionService>(
      () => CloudFunctionUserDeletionService(),
      'UserDeletionService',
    );
    
    // Register the service by interface type as well
    Get.put<UserDeletionService>(Get.find<CloudFunctionUserDeletionService>(), permanent: true);
    
    await _initializeService<NewsService>(
      () => NewsService(),
      'NewsService',
    );
    
    await _initializeService<DailyTaskNotificationService>(
      () => DailyTaskNotificationService(),
      'DailyTaskNotificationService',
    );
    
    await _initializeService<AccessControlService>(
      () => AccessControlService(),
      'AccessControlService',
    );
    
    // Initialize new architecture services
    await _initializeService<StartupOptimizationService>(
      () => StartupOptimizationService(),
      'StartupOptimizationService',
    );
    
    // Initialize ResponsiveController
    await _initializeService<ResponsiveController>(
      () => ResponsiveController(),
      'ResponsiveController',
    );
    
    await _initializeService<IntelligentCacheService>(
      () => IntelligentCacheService(),
      'IntelligentCacheService',
    );
    
    await _initializeService<CacheManager>(
      () => CacheManager(),
      'CacheManager',
    );
    
    await _initializeService<CachedTaskService>(
      () => CachedTaskService(),
      'CachedTaskService',
    );
    
    await _initializeService<EnhancedNotificationService>(
      () => EnhancedNotificationService(),
      'EnhancedNotificationService',
    );
    
    await _initializeService<NetworkService>(
      () => NetworkService(),
      'NetworkService',
    );
    
    await _initializeService<ConnectivityService>(
      () => ConnectivityService(),
      'ConnectivityService',
    );
    
    await _initializeService<ErrorHandlingService>(
      () => ErrorHandlingService(),
      'ErrorHandlingService',
    );
    
    await _initializeService<LoadingStateService>(
      () => LoadingStateService(),
      'LoadingStateService',
    );
    
    await _initializeService<OfflineDataService>(
      () => OfflineDataService(),
      'OfflineDataService',
    );
    
    // Initialize controllers that depend on services
    
    Get.put(AuthController(), permanent: true);
    
    Get.put(AppLockController(), permanent: true);
    
    Get.put(ThemeController(), permanent: true);
    
    Get.put(SettingsController(audioPlayer), permanent: true);
    
    // Initialize QuarterlyTransitionController
    
    Get.put(QuarterlyTransitionController(), permanent: true);
    
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
    
    
    Get.put(ManageUsersController(Get.find<CloudFunctionUserDeletionService>()), permanent: true);
   
    // Mark app as ready for snackbars BEFORE initializing controllers that might use them
    SnackbarUtils.markAppAsReady();
    
    Get.put(NotificationController(), permanent: true);
    
    Get.put(PrivacyController(), permanent: true);
    
    Get.put(WallpaperController(), permanent: true);
    
    // Initialize QuarterlyTransitionService
   
    await _initializeService(() => QuarterlyTransitionService(), 'QuarterlyTransitionService');
    
    
    // Mark bootstrap as complete
    _isBootstrapComplete = true;
    
    // Execute startup optimization
    try {
      await StartupOptimizationService.to.executeStartup();
    } catch (e) {
      debugPrint('Startup optimization failed: $e');
    }
    
    // Ensure widgets are properly initialized
    WidgetsFlutterBinding.ensureInitialized();
    
    // Run the app
    runApp(const MyApp());
   
    
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

Future<void> _verifyFirebaseServices() async {
  try {
    await FirebaseFirestore.instance.collection('test').limit(1).get();

    final rtdb = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://task-e5a96-default-rtdb.firebaseio.com',
    );
    // --- CORRECTED: Only one call is needed ---
    await rtdb.ref('.info/connected').once();
  } catch (e) {
    
    throw Exception(
      'Firebase service verification failed: $e\nPlease check your internet connection or Firebase configuration.',
    );
  }
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
