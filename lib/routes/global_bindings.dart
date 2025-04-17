// routes/global_bindings.dart
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';

class GlobalBindings extends Bindings {
  @override
  void dependencies() {
    // Make AuthController permanent so it doesn't get disposed
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
    Get.lazyPut<AdminController>(() => AdminController(), fenix: true);

    // Other controllers
    Get.lazyPut<AdminController>(() => AdminController());
  }
}
