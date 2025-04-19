// routes/global_bindings.dart
import 'package:get/get.dart';
import 'package:task/controllers/notification_controller.dart';
import 'package:task/service/firebase_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';

class GlobalBindings extends Bindings {
  @override
  void dependencies() {

    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<AdminController>(AdminController(), permanent: true);
    // Make AuthController permanent so it doesn't get disposed
    Get.lazyPut<FirebaseService>(() => FirebaseService(), fenix: true);
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
    Get.lazyPut<AdminController>(() => AdminController(), fenix: true);

    // Other controllers
    Get.lazyPut<AdminController>(() => AdminController());
    Get.lazyPut<NotificationController>(() => NotificationController());
  }
}
