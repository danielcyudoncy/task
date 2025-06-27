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

import 'package:task/controllers/auth_controller.dart';
import 'package:task/controllers/theme_controller.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/controllers/user_controller.dart';
import 'package:task/controllers/chat_controller.dart';
import 'package:task/firebase_options.dart';
import 'package:task/myApp.dart';
import 'package:task/service/mock_user_deletion_service.dart';
import 'package:task/service/presence_service.dart';

Future<void> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Load environment variables
    await dotenv.load(fileName: "assets/.env");

    // 2. Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 3. Verify Firebase services
    await _verifyFirebaseServices();

    // 4. Initialize Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      debug: kDebugMode,
    );

    // 5. Initialize Audio Player with global audio context
    final audioPlayer = await _initializeAudioPlayer();

    // 6. Validate mock usage (warn for production)
    _validateMockUsage();

    // 7. Register global GetX controllers
    Get.put(ThemeController(), permanent: true);
    Get.put(SettingsController(audioPlayer), permanent: true);
    Get.put(AuthController(), permanent: true);
    Get.put(UserController(MockUserDeletionService()), permanent: true);
    Get.put(PresenceService(), permanent: true);
    Get.put(ChatController(), permanent: true);

    // 8. Set presence online
    await Get.find<PresenceService>().setOnline();
    await Get.find<UserController>().updateUserPresence(true);

    // 9. Launch the app
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint("""
🚨 BOOTSTRAP FAILED
Error: $e
StackTrace: $stackTrace
""");

    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(title: const Text('Initialization Error')),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'App failed to initialize',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 10),
              Text(
                e.toString(),
                style: const TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => bootstrapApp(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    ));
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
