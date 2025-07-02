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

Future<void> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Step 1: Initialize external services and libraries first.
    await dotenv.load(fileName: "assets/.env");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await _verifyFirebaseServices();
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      debug: kDebugMode,
    );
    final audioPlayer = await _initializeAudioPlayer();

    // Step 2: Initialize controllers that DO NOT depend on user authentication.
    Get.put(ThemeController(), permanent: true);
    Get.put(SettingsController(audioPlayer), permanent: true);

    // Step 3: Initialize AuthController AND WAIT for it to be ready.
    // This is the gatekeeper for all other initializations.
    Get.put(AuthController(), permanent: true);
    await Get.find<AuthController>()
        .onReady; // Pauses here until auth state is known.

    // Step 4: Initialize all controllers that MAY depend on the user's auth state.
    // This is now safe because the await above has completed.
    Get.put(AdminController(), permanent: true);
    Get.put(UserController(MockUserDeletionService()), permanent: true);
    Get.put(PresenceService(), permanent: true);
    Get.put(ChatController(), permanent: true);
    Get.put(TaskController(), permanent: true);
    Get.put(ManageUsersController(MockUserDeletionService()), permanent: true);
    Get.put(NotificationController(), permanent: true);

    // Add SnackbarController here if it's a global controller.
    // If it's not a file in your project, you can ignore this line.
    // Get.put(SnackbarController(), permanent: true);

    // Step 5: Perform actions that require initialized controllers.
    final authController = Get.find<AuthController>();
    if (authController.isLoggedIn) {
      // These calls are now safe.
      await Get.find<PresenceService>().setOnline();
      await Get.find<UserController>().updateUserPresence(true);
    }

    // Step 6: Validate mock usage.
    _validateMockUsage();

    // Step 7: Launch the app.
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint("""
🚨 BOOTSTRAP FAILED
Error: $e
StackTrace: $stackTrace
""");
    // Your error UI
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
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.defaultToSpeaker,
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
    await FirebaseDatabase.instance.ref('.info/connected').once();
  } catch (e) {
    debugPrint("⚠️ Firebase check failed: $e");
    throw Exception(
      'Firebase service verification failed: $e\nPlease check your internet connection or Firebase configuration.',
    );
  }
}
