// routes/global_bindings.dart
import 'package:get/get.dart';
import 'package:task/controllers/manage_users_controller.dart';
import 'package:task/controllers/notification_controller.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/service/firebase_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';

class GlobalBindings extends Bindings {
  @override
  void dependencies() {
    // Permanent controllers
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<AdminController>(AdminController(), permanent: true);
    Get.put(SettingsController(), permanent: true);

    // Lazy-loaded controllers and services
    Get.lazyPut<FirebaseService>(() => FirebaseService(), fenix: true);
    Get.lazyPut<ManageUsersController>(() => ManageUsersController(),
        fenix: true);
    Get.lazyPut<NotificationController>(() => NotificationController(),
        fenix: true);
  }
}
