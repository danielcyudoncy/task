// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:task/firebase_options.dart';
import 'package:task/myApp.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load environment variables
  await dotenv.load(fileName: "assets/.env");

  try {
    // ✅ Initialize Firebase
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // ✅ Run the app after Firebase initialization
    runApp(const MyApp());
  } catch (e) {
    // Handle Firebase initialization failure
    print("❌ Firebase Initialization Failed: $e");
    runApp(const ErrorApp(error: "Failed to initialize Firebase."));
  }
}

// Fallback error app if initialization fails
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
