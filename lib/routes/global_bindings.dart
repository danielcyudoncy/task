// routes/global_bindings.dart
import 'package:get/get.dart';
import 'package:task/controllers/manage_users_controller.dart';
import 'package:task/controllers/notification_controller.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:task/service/firebase_service.dart';
import 'package:task/service/mock_user_deletion_service.dart';
import '../controllers/admin_controller.dart';

class GlobalBindings extends Bindings {
  @override
  void dependencies() {
    // Initialize AudioPlayer first

    // Permanent controllers
   
    Get.put<AdminController>(AdminController(), permanent: true);
   

    // Lazy-loaded controllers and services
    Get.lazyPut<FirebaseService>(() => FirebaseService(), fenix: true);
    Get.lazyPut<TaskController>(() => TaskController(), fenix: true);
    
    

    Get.lazyPut<ManageUsersController>(
      () => ManageUsersController(MockUserDeletionService()),
      fenix: true,
    );

    Get.lazyPut<NotificationController>(() => NotificationController(),
        fenix: true);
  }
}
