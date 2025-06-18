// core/bootstrap.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/firebase_options.dart';
import 'package:task/controllers/theme_controller.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/controllers/user_controller.dart';
import 'package:task/service/mock_user_deletion_service.dart'; // Mock only
import 'package:task/myApp.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ▶️ Warn if mock service is used in production
void _validateMockUsage() {
  if (kReleaseMode) {
    debugPrint("""
    ⚠️ WARNING: Using MockUserDeletionService in production!
    Replace with CloudFunctionUserDeletionService once Firebase payments are ready.
    """);
    // Optional: Throw an exception to force attention in production
    // throw Exception("Mock service detected in production!");
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
    Get.put(UserController(MockUserDeletionService())); // ◀️ Mock only

    // 6. Initialize Firestore metrics (optional)
    try {
      final docRef = FirebaseFirestore.instance
          .collection('dashboard_metrics')
          .doc('summary');
      if (!(await docRef.get()).exists) {
        await docRef.set({
          'totalUsers': 0,
          'tasks': {'total': 0, 'completed': 0, 'pending': 0, 'overdue': 0},
        });
      }
    } catch (e) {
      debugPrint("⚠️ Firestore metrics skipped: $e");
    }

    // 7. Run the app
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint("""
    🚨 BOOTSTRAP FAILED
    Error: $e
    StackTrace: $stackTrace
    """);
    runApp(
        const ErrorApp(error: "App initialization failed. Please try again later."));
  }
}

/// Error widget (unchanged)
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
            padding: EdgeInsets.all(24.w),
            child: Text(
              error,
              style: TextStyle(color: Colors.red, fontSize: 16.sp),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
