// routes/global_bindings.dart
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:task/controllers/chat_controller.dart';
import 'package:task/controllers/manage_users_controller.dart';
import 'package:task/controllers/notification_controller.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:task/controllers/user_controller.dart';
import 'package:task/service/cloud_function_user_deletion_service.dart';
import 'package:task/service/firebase_service.dart';
import 'package:task/service/mock_user_deletion_service.dart';
import 'package:task/service/presence_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/admin_controller.dart';


// For production, use: import 'package:task/services/cloud_function_user_deletion_service.dart';

class GlobalBindings extends Bindings {
  @override
  void dependencies() {
    // Permanent controllers
    Get.put<AuthController>(AuthController(), permanent: true); // FIRST
    Get.put<AdminController>(AdminController(), permanent: true);
    Get.put<SettingsController>(SettingsController(), permanent: true);
    // Get.put<TaskController>(TaskController(), permanent: true);

    // Lazy-loaded controllers and services
    Get.lazyPut<FirebaseService>(() => FirebaseService(), fenix: true);
    Get.lazyPut<TaskController>(() => TaskController(), fenix: true);
    Get.lazyPut(() => PresenceService(), fenix: true);
    Get.lazyPut(() => ChatController(), fenix: true);
    Get.lazyPut(
        () => UserController(kDebugMode
            ? MockUserDeletionService()
            : CloudFunctionUserDeletionService()),
        fenix: true);

    // 👇 Updated: Inject the service into ManageUsersController
    Get.lazyPut<ManageUsersController>(
      () => ManageUsersController(MockUserDeletionService()),
      fenix: true,
    );
    // For production, use:
    // Get.lazyPut<ManageUsersController>(
    //   () => ManageUsersController(CloudFunctionUserDeletionService()),
    //   fenix: true,
    // );

    Get.lazyPut<NotificationController>(() => NotificationController(),
        fenix: true);
  }
}
