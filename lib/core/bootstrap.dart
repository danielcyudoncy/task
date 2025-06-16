// core/bootstrap.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/firebase_options.dart';
import 'package:task/controllers/theme_controller.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/controllers/user_controller.dart';
import 'package:task/service/mock_user_deletion_service.dart';
// For production, use: import 'package:task/services/cloud_function_user_deletion_service.dart';
import 'package:task/myApp.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Initializes Firestore dashboard metrics if they do not exist.
Future<void> _initializeFirestoreMetrics() async {
  final docRef =
      FirebaseFirestore.instance.collection('dashboard_metrics').doc('summary');

  final doc = await docRef.get();
  if (!doc.exists) {
    await docRef.set({
      'totalUsers': 0,
      'tasks': {
        'total': 0,
        'completed': 0,
        'pending': 0,
        'overdue': 0,
      },
    });
  }
}

/// Bootstraps the Flutter app by initializing essential services and controllers.
Future<void> bootstrapApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Load environment variables
    await dotenv.load(fileName: "assets/.env");

    // ✅ Initialize Firebase FIRST
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // ✅ Then initialize Supabase
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      debug: true,
    );

    // Register controllers globally
    Get.put(ThemeController(), permanent: true);
    Get.put(SettingsController(), permanent: true);
    Get.put(AuthController(), permanent: true);

    // ✅ Inject UserController here (with deletion service)
    Get.put(UserController(MockUserDeletionService()));
    // For production, use:
    // Get.put(UserController(CloudFunctionUserDeletionService()));

    // Initialize metrics (safely)
    try {
      await _initializeFirestoreMetrics();
    } catch (e) {
      debugPrint("⚠️ Firestore metric initialization failed: $e");
    }

    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint("❌ Initialization Failed: $e");
    debugPrint("📌 StackTrace: $stackTrace");

    runApp(const ErrorApp(error: "Failed to initialize Firebase or Supabase."));
  }
}

/// Simple error UI for failed initialization.
class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              error,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
