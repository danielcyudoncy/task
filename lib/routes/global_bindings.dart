// routes/global_bindings.dart
import 'package:get/get.dart';
import 'package:task/controllers/admin_controller.dart';

class GlobalBindings extends Bindings {
  @override
  void dependencies() {
    print("GlobalBindings initialized"); // Debug statement
    Get.put<AdminController>(AdminController(),
        permanent: true); // Ensure AdminController persists
  }
}
