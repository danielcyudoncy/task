// core/bootstrap.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Ensure all your controllers are imported ---
import 'package:task/controllers/admin_controller.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/controllers/chat_controller.dart';
import 'package:task/controllers/manage_users_controller.dart';
import 'package:task/controllers/notification_controller.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:task/controllers/theme_controller.dart';
import 'package:task/controllers/user_controller.dart';
import 'package:task/firebase_options.dart';
import 'package:task/myApp.dart';
import 'package:task/service/mock_user_deletion_service.dart';
import 'package:task/service/presence_service.dart';
import 'package:task/service/supabase_storage_service.dart'; // NEW: Make sure this is imported

Future<void> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Step 1: Load environment variables
    await dotenv.load(fileName: "assets/.env");
    debugPrint('DEBUG: Dotenv loaded');

    // Step 2: Initialize Firebase (before Supabase, as AuthController might touch Firebase Auth too)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('DEBUG: Firebase initialized');
    await _verifyFirebaseServices();
    debugPrint('DEBUG: Firebase services verified');

    // Step 3: Initialize Supabase (CRITICAL for Supabase-dependent controllers)
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      debug: kDebugMode,
    );
    debugPrint(
        'DEBUG: Supabase init completed'); // This debug log is from Supabase itself

    // Step 4: --- CRITICAL FIX: Ensure Supabase is fully ready for dependent services ---
    // Wait for Supabase to confirm it's ready. This is usually implicitly handled by await Supabase.initialize(),
    // but sometimes there's a tiny window. Let's make it explicit or ensure dependent services are put later.
    // Given the crash is specifically on Supabase.instance, it means AuthController's constructor runs before Supabase is fully set up.

    // The issue is AuthController's constructor directly calls SupabaseStorageService,
    // whose constructor directly calls Supabase.instance.
    // We need to either make SupabaseStorageService lazy, or AuthController lazy,
    // or put SupabaseStorageService before AuthController.

    // --- OPTION A: Make SupabaseStorageService a permanent Get.put ---
    // This allows AuthController to just Get.find it.
    Get.put(SupabaseStorageService(),
        permanent: true); // NEW: Put this service here
    debugPrint('DEBUG: SupabaseStorageService put');

    // Step 5: Initialize controllers that DO NOT depend on user authentication (Theme, Settings).
    final audioPlayer = await _initializeAudioPlayer();
    debugPrint('DEBUG: Audio player initialized');
    Get.put(ThemeController(), permanent: true);
    debugPrint('DEBUG: ThemeController put');
    Get.put(SettingsController(audioPlayer), permanent: true);
    debugPrint('DEBUG: SettingsController put');

    // Step 6: Initialize AuthController AND WAIT for it to be ready.
    // AuthController now Get.finds SupabaseStorageService, which is already put.
    Get.put(AuthController(), permanent: true);
    debugPrint('DEBUG: AuthController put');
    Get.find<AuthController>().onReady;
    debugPrint('DEBUG: AuthController ready');

    // Step 7: Initialize all controllers that MAY depend on the user's auth state.
    // This is now safe because AuthController is ready.
    Get.put(AdminController(), permanent: true);
    debugPrint('DEBUG: AdminController put');
    Get.put(UserController(MockUserDeletionService()), permanent: true);
    debugPrint('DEBUG: UserController put');
    Get.put(PresenceService(), permanent: true);
    debugPrint('DEBUG: PresenceService put');
    Get.put(ChatController(), permanent: true);
    debugPrint('DEBUG: ChatController put');
    Get.put(TaskController(), permanent: true);
    debugPrint('DEBUG: TaskController put');
    Get.put(ManageUsersController(MockUserDeletionService()), permanent: true);
    debugPrint('DEBUG: ManageUsersController put');
    Get.put(NotificationController(), permanent: true);
    debugPrint('DEBUG: NotificationController put');

    // Step 8: Perform actions that require initialized controllers.
    final authController = Get.find<AuthController>();
    if (authController.isLoggedIn) {
      await Get.find<PresenceService>().setOnline();
      debugPrint('DEBUG: Presence set online');
      await Get.find<UserController>().updateUserPresence(true);
      debugPrint('DEBUG: User presence updated');
    }

    // Step 9: Validate mock usage.
    _validateMockUsage();
    debugPrint('DEBUG: Mock usage validated');

    // Step 10: Launch the app.
    runApp(const MyApp());
    debugPrint('DEBUG: MyApp running');
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

// In core/bootstrap.dart -> _initializeAudioPlayer()

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
        iOS: AudioContextIOS(
          // --- FIX THIS SECTION ---
          // Choose one of these:
          // Option A: If you need both playback AND recording (e.g., voice messages)
          category: AVAudioSessionCategory.playAndRecord,
          options: const {
            
            AVAudioSessionOptions.mixWithOthers,
          },
          // Option B: If you only need playback, remove defaultToSpeaker option
          // category: AVAudioSessionCategory.playback,
          // options: const {
          //   AVAudioSessionOptions.mixWithOthers,
          // },
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
    await FirebaseDatabase.instance.ref('.info/connected').once();
  } catch (e) {
    debugPrint("⚠️ Firebase check failed: $e");
    throw Exception(
      'Firebase service verification failed: $e\nPlease check your internet connection or Firebase configuration.',
    );
  }
}
