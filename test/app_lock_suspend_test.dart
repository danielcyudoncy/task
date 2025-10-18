// test/app_lock_suspend_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:task/controllers/app_lock_controller.dart';

// test/app_lock_suspend_test.dart
import 'package:flutter/material.dart';

// Minimal fake AuthController used for tests
// Create minimal fake classes that do not initialize Firebase
class _FakeAuthController extends GetxController {
  User? get currentUser => null;
  Future<void> navigateBasedOnRole() async {}
}

class _FakeBiometricService extends GetxService {
  final RxBool isBiometricAvailable = false.obs;
  IconData getBiometricIcon() => Icons.security;
  String getBiometricTypeString() => 'None';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    // Register fakes required by AppLockController
  // Register simple fakes to satisfy AppLockController dependencies
  Get.put<_FakeAuthController>(_FakeAuthController());
  Get.put<_FakeBiometricService>(_FakeBiometricService());
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
