// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ✅ Securely load .env variables
import 'package:task/controllers/admin_controller.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/firebase_options.dart';
import 'package:task/myApp.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Load environment variables
  await dotenv.load(fileName: "assets/.env");

  try {
    // ✅ Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // ✅ Ensure AuthController is initialized
    final authController = Get.put(AuthController());
    await authController.loadUserData(); // ✅ Load user data after login
    Get.put(AdminController());

    runApp(const MyApp());
  } catch (e) {
    print("❌ Firebase Initialization Failed: $e");
  }
}
