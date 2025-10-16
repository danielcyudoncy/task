// screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task/utils/constants/app_icons.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/core/bootstrap.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _textOpacityAnimation;
  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.5, curve: Curves.easeOutBack),
    ));

    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.5, 0.8, curve: Curves.easeIn),
    ));

    _controller.forward();
    Timer(const Duration(seconds: 3), () async {
      try {
        // Wait for bootstrap to complete
        while (!isBootstrapComplete) {
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Add a small delay to ensure all controllers are ready
        await Future.delayed(const Duration(milliseconds: 1000));

        // Mark app as ready for snackbars before navigation
        if (Get.isRegistered<AuthController>()) {
          Get.find<AuthController>().markAppAsReady();
        }

        final prefs = await SharedPreferences.getInstance();

        final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

        if (!hasSeenOnboarding) {
          Get.offAllNamed('/onboarding');
        } else {
          // Check if user is already logged in
          if (!Get.isRegistered<AuthController>()) {
            Get.offAllNamed('/login');
            return;
          }

          final authController = Get.find<AuthController>();

          // Wait a bit for Firebase auth to initialize
          await Future.delayed(const Duration(milliseconds: 500));

          if (authController.isLoggedIn) {
            // User is logged in, navigate based on role
            await authController.navigateBasedOnRole();
          } else {
            // User is not logged in, go to login screen
            Get.offAllNamed('/login');
          }
        }
      } catch (e) {
        // Fallback to login screen
        Get.offAllNamed('/login');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final orientation = MediaQuery.of(context).orientation;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculate responsive logo size based on orientation
    final logoSize = orientation == Orientation.portrait
        ? screenWidth * 0.4 // 40% of screen width in portrait
        : screenHeight * 0.35; // 35% of screen height in landscape

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? [Colors.grey[900]!, Colors.grey[800]!]
                  .reduce((value, element) => value)
              : Theme.of(context).colorScheme.primary,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo with rounded corners - responsive sizing
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Image.asset(
                      AppIcons.logo,
                      width: logoSize,
                      height: logoSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              SizedBox(height: orientation == Orientation.portrait ? 8.h : 6.h),
              FadeTransition(
                opacity: _textOpacityAnimation,
                child: Text(
                  'Your Home For The News'.tr,
                  style: textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontFamily: 'Raleway',
                    fontSize:
                        orientation == Orientation.portrait ? 16.sp : 14.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                  height: orientation == Orientation.portrait ? 16.h : 12.h),
              FadeTransition(
                opacity: _textOpacityAnimation,
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
