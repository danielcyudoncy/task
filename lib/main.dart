// main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/myApp.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ✅ Ensure AuthController is initialized
  final authController = Get.put(AuthController());
  await authController.loadUserData(); // ✅ Load Full Name if logged in

  runApp(const MyApp());
}
