// screens/route_handler_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/auth_controller.dart';

class RouteHandlerScreen extends StatelessWidget {
  const RouteHandlerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Get.find<AuthController>().auth.authStateChanges(),
      builder: (context, snapshot) {
        // Use a post-frame callback to handle navigation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleRouting(snapshot);
        });

        // Show a loading indicator while routing
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  void _handleRouting(AsyncSnapshot snapshot) {
    final authController = Get.find<AuthController>();

    if (snapshot.connectionState == ConnectionState.waiting) {
      return; // Wait for connection
    }

    if (snapshot.hasData && authController.currentUser != null) {
      final role = authController.userRole.value;
      if (role.isEmpty) {
        // Role not yet loaded, wait for it
        // A listener in AuthController should trigger a re-evaluation
        return;
      }

      // Navigate based on user role
      if (role == "Admin" ||
          role == "Assignment Editor" ||
          role == "Head of Department" ||
          role == "News Director" ||
          role == "Assistant News Director" ||
          role == "Head of Unit") {
        Get.offAllNamed('/admin-dashboard');
      } else if (role == "Librarian") {
        Get.offAllNamed('/librarian-dashboard');
      } else {
        Get.offAllNamed('/home');
      }
    } else {
      // No user, go to login
      Get.offAllNamed('/login');
    }
  }
}