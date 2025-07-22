// core/bootstrap.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/task_model.dart';
import 'package:get/get.dart';
import '../routes/global_bindings.dart';
import '../my_app.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';  // Removed - using Firebase Storage

// --- Ensure all your controllers and services are imported ---
import 'package:task/controllers/admin_controller.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/controllers/chat_controller.dart';
import 'package:task/controllers/manage_users_controller.dart';
import 'package:task/controllers/notification_controller.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:task/controllers/theme_controller.dart';
import 'package:task/controllers/user_controller.dart';
import 'package:task/controllers/wallpaper_controller.dart';
import 'package:task/firebase_options.dart';
import 'package:task/my_app.dart';
import 'package:task/service/mock_user_deletion_service.dart';
import 'package:task/service/user_deletion_service.dart';
import 'package:task/service/cloud_function_user_deletion_service.dart';
import 'package:task/service/news_service.dart';
import 'package:task/service/presence_service.dart';
import 'package:task/service/firebase_storage_service.dart';
import 'package:task/service/firebase_service.dart' show useFirebaseEmulator;
import 'package:task/service/isar_task_service.dart';

// --- Emulator/Production Switch ---
const bool useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);
const String emulatorHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST', defaultValue: '192.168.1.7');

// Global flag to track bootstrap state
bool _isBootstrapComplete = false;
bool get isBootstrapComplete => _isBootstrapComplete;

Future<void> bootstrapApp() async {
  debugPrint("🚀 BOOTSTRAP: Starting app initialization");
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("🚀 BOOTSTRAP: WidgetsFlutterBinding initialized");

  try {
    // Step 1: Initialize external libraries
    debugPrint("🚀 BOOTSTRAP: Loading environment variables");
    await dotenv.load(fileName: "assets/.env");
    debugPrint("🚀 BOOTSTRAP: Environment variables loaded");
    debugPrint("🚀 BOOTSTRAP: Initializing Firebase");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Automatically connect to emulator if flag is set
    if (useEmulator) {
      useFirebaseEmulator(emulatorHost);
    }
    debugPrint("🚀 BOOTSTRAP: Firebase initialized");
    debugPrint("🚀 BOOTSTRAP: Verifying Firebase services");
    await _verifyFirebaseServices();
    debugPrint("🚀 BOOTSTRAP: Firebase services verified");

    debugPrint("🚀 BOOTSTRAP: Skipping Supabase initialization - using Firebase Storage");

    // Step 2: Open Isar and register IsarTaskService BEFORE any controller
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open([TaskSchema], directory: dir.path);
    Get.put(IsarTaskService(isar), permanent: true);

    // Step 3: Initialize services and controllers with no dependencies
    debugPrint("🚀 BOOTSTRAP: Initializing audio player");
    final audioPlayer = await _initializeAudioPlayer();
    debugPrint("🚀 BOOTSTRAP: Audio player initialized");
    debugPrint("🚀 BOOTSTRAP: Putting ThemeController");
    Get.put(ThemeController(), permanent: true);
    debugPrint("🚀 BOOTSTRAP: Putting SettingsController");
    Get.put(SettingsController(audioPlayer), permanent: true);
    debugPrint("🚀 BOOTSTRAP: Basic controllers initialized");

    // --- THIS IS THE CORRECTED INITIALIZATION ORDER ---

    // Step 3: Put all services that other controllers depend on FIRST.
    debugPrint("🚀 BOOTSTRAP: Putting FirebaseStorageService");
    Get.put(FirebaseStorageService(), permanent: true);
    debugPrint("🚀 BOOTSTRAP: Putting UserDeletionService (mock or real)");
    if (kReleaseMode) {
      Get.put<UserDeletionService>(CloudFunctionUserDeletionService(), permanent: true);
    } else {
      Get.put<UserDeletionService>(MockUserDeletionService(), permanent: true);
    }
    debugPrint("🚀 BOOTSTRAP: Putting NewsService");
    Get.put(NewsService(), permanent: true); // News service for real-time news
    debugPrint("🚀 BOOTSTRAP: Services initialized");

    // Step 4: Put the AuthController (no need to await onReady)
    debugPrint('🚀 BOOTSTRAP: Putting AuthController...');
    Get.put(AuthController(), permanent: true);
    debugPrint('🚀 BOOTSTRAP: AuthController put successfully');

    // Step 5: Put all remaining controllers. They can now safely find their dependencies.
    debugPrint('🚀 BOOTSTRAP: Putting remaining controllers...');
    debugPrint('🚀 BOOTSTRAP: Putting AdminController');
    Get.put(AdminController(), permanent: true);
    debugPrint('🚀 BOOTSTRAP: Putting UserController');
    Get.put(UserController(Get.find<UserDeletionService>()), permanent: true);
    debugPrint('🚀 BOOTSTRAP: Putting PresenceService');
    Get.put(PresenceService(), permanent: true);
    debugPrint('🚀 BOOTSTRAP: Putting ChatController');
    Get.put(ChatController(), permanent: true);
    debugPrint('🚀 BOOTSTRAP: Putting TaskController');
    Get.put(TaskController(), permanent: true);
    debugPrint('🚀 BOOTSTRAP: Putting ManageUsersController');
    Get.put(ManageUsersController(Get.find<UserDeletionService>()), permanent: true);
    debugPrint('🚀 BOOTSTRAP: Putting NotificationController');
    Get.put(NotificationController(), permanent: true);
    debugPrint('🚀 BOOTSTRAP: Putting WallpaperController');
    Get.put(WallpaperController(), permanent: true);
    debugPrint('🚀 BOOTSTRAP: All controllers put successfully');

    // Step 6: Perform post-initialization actions (simplified to prevent issues)
    debugPrint('🚀 BOOTSTRAP: Performing post-initialization actions...');
    debugPrint('🚀 BOOTSTRAP: Skipping complex post-initialization to prevent issues');

    debugPrint('🚀 BOOTSTRAP: Validating mock usage');
    _validateMockUsage();

    // Step 7: Launch the app
    debugPrint('🚀 BOOTSTRAP: Launching app...');
    
    // Add a delay to ensure all initialization is complete
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Mark bootstrap as complete
    _isBootstrapComplete = true;
    debugPrint('🚀 BOOTSTRAP: Bootstrap marked as complete');
    
    runApp(
      MyApp(isar: isar),
    );
    debugPrint('🚀 BOOTSTRAP: App launched successfully');
  } catch (e, stackTrace) {
    debugPrint('DEBUG: CRASH CAUGHT!');
    debugPrint('Error Type: ${e.runtimeType}');
    debugPrint('Error Message: $e');
    debugPrint('Stack Trace:\n$stackTrace');
    runApp(MaterialApp(
        home: Scaffold(body: Center(child: Text('Bootstrap Failed: $e')))));
  }
}

void _validateMockUsage() {
  if (kReleaseMode) {
    debugPrint("""
⚠️ WARNING: Using MockUserDeletionService in production!
Replace with CloudFunctionUserDeletionService once Firebase payments are ready.
""");
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
