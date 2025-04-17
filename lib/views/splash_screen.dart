// views/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:task/controllers/admin_controller.dart';
import 'package:task/service/analytics_service.dart';
import '../controllers/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthController _auth = Get.find();
  final _stopwatch = Stopwatch();
  bool _showError = false;
  bool _offlineMode = false;
  bool _initialized = false;
  late final InternetConnectionChecker _connectionChecker;
  late StreamSubscription<InternetConnectionStatus> _connectionListener;

  @override
  void initState() {
    super.initState();
    _connectionChecker = InternetConnectionChecker.createInstance();
    _stopwatch.start();
    _setupConnectionMonitoring();
    _initializeApp();
  }

  void _setupConnectionMonitoring() {
    _connectionListener = _connectionChecker.onStatusChange.listen((status) {
      if (mounted) {
        setState(() {
          _offlineMode = status == InternetConnectionStatus.disconnected;
        });
        if (status == InternetConnectionStatus.connected &&
            _offlineMode &&
            !_initialized) {
          _retryInitialization();
        }
      }
    });
  }

  Future<void> _initializeApp() async {
    try {
      // Initial connectivity check
      final isConnected = await _connectionChecker.hasConnection;
      if (!isConnected) {
        if (mounted) setState(() => _offlineMode = true);
      }

      await Future.wait([
        Future.delayed(const Duration(seconds: 2)), // Minimum splash duration
        _checkAuthState(),
      ]);

      _initialized = true;
    } catch (e) {
      _handleInitializationError(e);
    } finally {
      if (mounted) {
        _stopwatch.stop();
        AnalyticsService.trackEvent(
          name: 'splash_initialized',
          params: {'duration_ms': _stopwatch.elapsedMilliseconds},
        );
      }
    }
  }

  Future<void> _retryInitialization() async {
    if (mounted) setState(() => _showError = false);
    await _initializeApp();
  }

  Future<void> _checkAuthState() async {
    try {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          Get.offAllNamed("/login");
          return;
        }

        // Initialize AuthController
        await _auth.loadUserData();

        // Special handling for admin role
        if (_auth.userRole.value == "Admin") {
          try {
            final adminController = Get.find<AdminController>();
            await adminController.fetchAdminProfile();

            if (adminController.adminName.value.isEmpty) {
              throw Exception("Admin profile not complete");
            }
          } catch (e) {
            debugPrint("Admin verification failed: $e");
            await _auth.logout();
            Get.offAllNamed("/login");
            return;
          }
        }

        // Proceed with navigation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _auth.navigateBasedOnRole();
        });
      } catch (e) {
        debugPrint("Auth check error: $e");
        await _auth.logout();
        Get.offAllNamed("/login");
      }

      AnalyticsService.trackEvent(
        name: 'splash_redirect',
        params: {'target': _auth.userRole.value},
      );

      // Ensure controller is ready before navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _auth.navigateBasedOnRole();
      });
    } catch (e) {
      debugPrint("Auth check error: $e");
      // Ensure we logout if there's any error
      await _auth.logout();
      _handleInitializationError(e);
    }
  }

  void _handleInitializationError(dynamic error) {
    debugPrint("Splash initialization error: $error");
    if (mounted) {
      setState(() => _showError = true);
      AnalyticsService.trackEvent(
        name: 'splash_error',
        params: {'reason': error.toString()},
      );
    }

    // Give user time to see error before redirect
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Get.offAllNamed("/login");
    });
  }

  @override
  void dispose() {
    _connectionListener.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'app-logo',
              child: Image.asset(
                "assets/png/logo.png",
                width: 150,
                errorBuilder: (_, __, ___) => const FlutterLogo(size: 150),
              ),
            ),
            const SizedBox(height: 30),
            if (_offlineMode)
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      "Offline Mode - Limited Functionality",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _retryInitialization,
                    child: const Text("Retry Connection"),
                  ),
                ],
              ),
            if (_showError) ...[
              const SizedBox(height: 20),
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                "Initialization Error",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 5),
              const Text("Redirecting to login..."),
            ],
            if (!_offlineMode && !_showError) ...[
              const SizedBox(height: 30),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
