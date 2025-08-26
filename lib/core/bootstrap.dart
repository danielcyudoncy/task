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
import '../my_app.dart';

// --- Ensure all your controllers and services are imported ---
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

// --- Emulator/Production Switch ---
const bool useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);
const String emulatorHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST', defaultValue: '192.168.1.7');

// Global flag to track bootstrap state
bool _isBootstrapComplete = false;
bool get isBootstrapComplete => _isBootstrapComplete;

Future<void> bootstrapApp() async {
  try {
    debugPrint("🚀 BOOTSTRAP: Starting app initialization");
    
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint("🚀 BOOTSTRAP: WidgetsFlutterBinding initialized");
    
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Initialize error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('🚨 FLUTTER ERROR: ${details.exception}');
      debugPrint('🚨 STACK TRACE: ${details.stack}');
    };
    
    // Set uncaught error handler
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('🚨 UNCAUGHT ERROR: $error');
      debugPrint('🚨 STACK TRACE: $stack');
      return true;
    };

    // Load environment variables
    debugPrint("🚀 BOOTSTRAP: Loading environment variables");
    await dotenv.load(fileName: "assets/.env");
    debugPrint("🚀 BOOTSTRAP: Environment variables loaded");

    // Initialize Firebase
    debugPrint("🚀 BOOTSTRAP: Initializing Firebase");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Automatically connect to emulator if flag is set
    if (useEmulator) {
      useFirebaseEmulator(emulatorHost);
    }
    debugPrint("🚀 BOOTSTRAP: Firebase initialized");
    
    // Initialize Firebase services
    debugPrint("🚀 BOOTSTRAP: Verifying Firebase services");
    await _verifyFirebaseServices();
    debugPrint("🚀 BOOTSTRAP: Firebase services verified");
    
    // Initialize Firebase Messaging Service
    debugPrint("🚀 BOOTSTRAP: Initializing Firebase Messaging Service");
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    final firebaseMessagingService = FirebaseMessagingService();
    await firebaseMessagingService.initialize();
    Get.put(firebaseMessagingService, permanent: true);
    debugPrint("🚀 BOOTSTRAP: Firebase Messaging Service initialized");

    // Initialize other services
    debugPrint("🚀 BOOTSTRAP: Initializing SQLite TaskService");
    final taskService = TaskService();
    await taskService.initialize();
    Get.put(taskService, permanent: true);
    debugPrint("🚀 BOOTSTRAP: SQLite TaskService initialized");

    // Initialize audio player
    debugPrint("🚀 BOOTSTRAP: Initializing audio player");
    final audioPlayer = await _initializeAudioPlayer();
    debugPrint("🚀 BOOTSTRAP: Audio player initialized");
    
    // Initialize controllers
    debugPrint("🚀 BOOTSTRAP: Initializing controllers");
    Get.put(ThemeController(), permanent: true);
    Get.put(SettingsController(audioPlayer), permanent: true);
    
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
    
    debugPrint("🚀 BOOTSTRAP: Services initialized, now initializing controllers");
    
    // Initialize controllers that depend on services
    debugPrint('🚀 BOOTSTRAP: Putting AuthController...');
    Get.put(AuthController(), permanent: true);
    debugPrint('🚀 BOOTSTRAP: AuthController put successfully');

    debugPrint('🚀 BOOTSTRAP: Putting remaining controllers...');
    debugPrint('🚀 BOOTSTRAP: Putting AppLockController');
    Get.put(AppLockController(), permanent: true);
    debugPrint('🚀 BOOTSTRAP: Putting AdminController');
    Get.put(AdminController(), permanent: true);
    debugPrint('🚀 BOOTSTRAP: Putting UserController');
    Get.put(UserController(Get.find<CloudFunctionUserDeletionService>()), permanent: true);
    debugPrint('🚀 BOOTSTRAP: Putting PresenceService');
    Get.put(PresenceService(), permanent: true);
    debugPrint('🚀 BOOTSTRAP: Putting ChatController');
    Get.put(ChatController(), permanent: true);
    debugPrint('🚀 BOOTSTRAP: Putting TaskController');
    Get.put(TaskController(), permanent: true);
    
    // Initialize services that depend on controllers
    await _initializeService<BulkOperationsService>(
      () => BulkOperationsService(),
      'BulkOperationsService',
    );
    
    debugPrint("🚀 BOOTSTRAP: All services and controllers initialized successfully");
    debugPrint('🚀 BOOTSTRAP: Putting ManageUsersController');
    Get.put(ManageUsersController(Get.find<CloudFunctionUserDeletionService>()), permanent: true);
    debugPrint('🚀 BOOTSTRAP: Putting NotificationController');
    Get.put(NotificationController(), permanent: true);
    debugPrint('🚀 BOOTSTRAP: Putting PrivacyController');
    Get.put(PrivacyController(), permanent: true);
    debugPrint('🚀 BOOTSTRAP: Putting WallpaperController');
    Get.put(WallpaperController(), permanent: true);

    debugPrint('🚀 BOOTSTRAP: All controllers initialized successfully');
    
    // Mark app as ready for snackbars
    SnackbarUtils.markAppAsReady();
    debugPrint('🚀 BOOTSTRAP: App marked as ready for snackbars');
    
    // Mark bootstrap as complete
    _isBootstrapComplete = true;
    debugPrint('🚀 BOOTSTRAP: Bootstrap marked as complete');
    
    // Ensure widgets are properly initialized
    WidgetsFlutterBinding.ensureInitialized();
    
    // Run the app
    runApp(const MyApp());
    debugPrint('🚀 BOOTSTRAP: App launched successfully');
    
  } catch (e, stack) {
    debugPrint('🚨 CRITICAL ERROR during bootstrap: $e');
    debugPrint('🚨 STACK TRACE: $stack');
    
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

Future<void> _initializeService<T extends GetxService>(
  T Function() create, 
  String serviceName
) async {
  try {
    debugPrint("🚀 BOOTSTRAP: Initializing $serviceName");
    final service = create();
    // Simply put the service into GetX without calling any methods
    // Most GetxService implementations don't need explicit initialization
    Get.put<T>(service, permanent: true);
    debugPrint("✅ $serviceName initialized successfully");
  } catch (e, stack) {
    debugPrint('❌ Failed to initialize $serviceName: $e');
    debugPrint('Stack trace: $stack');
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
  } catch (e) {
    debugPrint('⚠️ Audio context setup error: $e');
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
    debugPrint("⚠️ Firebase check failed: $e");
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
  
  debugPrint("Handling background message: ${message.messageId}");
}
