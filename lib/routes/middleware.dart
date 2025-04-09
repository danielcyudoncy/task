// routes/middleware.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Use Firebase Auth directly
    final firebaseAuth = FirebaseAuth.instance;

    // Check if user is authenticated with Firebase
    if (firebaseAuth.currentUser == null) {
      // No user is signed in, redirect to login
      print("AuthMiddleware: User not authenticated. Redirecting to /login.");
      return const RouteSettings(name: '/login');
    }

    // User is signed in, proceed to requested route
    print("AuthMiddleware: User authenticated. Proceeding to $route.");
    return null;
  }
}
