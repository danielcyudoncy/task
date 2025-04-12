import 'package:get/get.dart';
import 'package:task/controllers/admin_controller.dart';
import 'package:task/controllers/auth_controller.dart';

class GlobalBindings extends Bindings {
  @override
  void dependencies() {
    print("GlobalBindings initialized");

    // Lazy load AdminController
    if (!Get.isRegistered<AdminController>()) {
      Get.lazyPut<AdminController>(() => AdminController());
    }

    // Lazy load AuthController
    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut<AuthController>(() => AuthController());
    }
  }
}