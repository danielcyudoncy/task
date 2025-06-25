// core/bootstrap.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/firebase_options.dart';
import 'package:task/controllers/theme_controller.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/controllers/user_controller.dart';
import 'package:task/controllers/chat_controller.dart';
import 'package:task/myApp.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:task/service/mock_user_deletion_service.dart';
import 'package:task/service/presence_service.dart';

void _validateMockUsage() {
  if (kReleaseMode) {
    debugPrint("""
    ⚠️ WARNING: Using MockUserDeletionService in production!
    Replace with CloudFunctionUserDeletionService once Firebase payments are ready.
    """);
  }
}

Future<void> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Load environment variables
    await dotenv.load(fileName: "assets/.env");

    // 2. Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 3. Initialize Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      debug: kDebugMode,
    );

    // 4. Warn about mock usage (non-blocking)
    _validateMockUsage();

    // 5. Register controllers
    Get.put(ThemeController(), permanent: true);
    Get.put(SettingsController(), permanent: true);
    Get.put(AuthController(), permanent: true);

    // Initialize UserController with required service
    Get.put(UserController(MockUserDeletionService()), permanent: true);

    // Initialize Chat-related services
    Get.put(PresenceService(), permanent: true);
    Get.put(ChatController(), permanent: true);

     // Initialize presence
    await Get.find<PresenceService>().setOnline();

    // Set initial online status
    await Get.find<UserController>().updateUserPresence(true);

    // 7. Run the app
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint("""
    🚨 BOOTSTRAP FAILED
    Error: $e
    StackTrace: $stackTrace
    """);
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('App initialization failed. Please try again later.'),
          ),
        ),
      ),
    );
  }
}
