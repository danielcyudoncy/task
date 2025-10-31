// ui/screens/route_handler_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/auth_controller.dart';

class RouteHandlerScreen extends StatefulWidget {
  const RouteHandlerScreen({super.key});

  @override
  State<RouteHandlerScreen> createState() => _RouteHandlerScreenState();
}

class _RouteHandlerScreenState extends State<RouteHandlerScreen> {
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _authController.isRoleLoaded.stream.listen((isLoaded) {
      if (isLoaded) {
        _authController.navigateBasedOnRole();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}