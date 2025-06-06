// core/bootstrap.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:task/firebase_options.dart';
import 'package:task/controllers/theme_controller.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/myApp.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    await dotenv.load(fileName: "assets/.env");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Register controllers globally
    Get.put(ThemeController(), permanent: true);
    Get.put(SettingsController(), permanent: true);

    // Initialize metrics BEFORE running the app
    await _initializeFirestoreMetrics();

    runApp(const MyApp());
  } catch (e) {
    debugPrint("❌ Firebase Initialization Failed: $e");
    runApp(const ErrorApp(error: "Failed to initialize Firebase."));
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
        body: Center(
          child: Text(error, style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}
