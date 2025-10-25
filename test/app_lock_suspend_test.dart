// test/app_lock_suspend_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:task/controllers/app_lock_controller.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/service/biometric_service.dart';
import 'package:flutter/material.dart';

// Create simple stub classes that implement the required interfaces
class StubAuthController extends GetxController implements AuthController {
  @override
  User? get currentUser => null;
  
  @override
  Future<void> navigateBasedOnRole() async {}
  
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class StubBiometricService extends GetxService implements BiometricService {
  @override
  final RxBool isBiometricAvailable = false.obs;
  
  @override
  IconData getBiometricIcon() => Icons.security;
  
  @override
  String getBiometricTypeString() => 'None';
  
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    // Register stubs required by AppLockController with correct types
    Get.put<AuthController>(StubAuthController());
    Get.put<BiometricService>(StubBiometricService());
    // Now register the AppLockController
    Get.put<AppLockController>(AppLockController());
  });

  test('suspendLockWhile suspends and resumes correctly', () async {
    final controller = Get.find<AppLockController>();

    // Start a future that completes after a short delay
    final future = Future.delayed(const Duration(milliseconds: 100), () => 42);

    final resultFuture = controller.suspendLockWhile(future);

    // Immediately after calling, suspension count should be > 0
    expect(controller.isLockSuspended, isTrue);

    final result = await resultFuture;
    expect(result, 42);

    // After completion, suspension should be cleared
    expect(controller.isLockSuspended, isFalse);
  });
}
