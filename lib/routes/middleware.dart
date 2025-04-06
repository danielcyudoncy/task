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
      return const RouteSettings(name: '/login');
    }
    
    // User is signed in, proceed to requested route
    return null;
  }
}