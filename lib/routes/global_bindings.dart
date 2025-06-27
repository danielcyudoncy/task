// routes/global_bindings.dart
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
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

class GlobalBindings extends Bindings {
  @override
  void dependencies() {
    // Initialize AudioPlayer first
    final audioPlayer = AudioPlayer()
      ..setReleaseMode(ReleaseMode.stop)
      ..setPlayerMode(PlayerMode.mediaPlayer);

    // Permanent controllers
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<AdminController>(AdminController(), permanent: true);
    Get.put<SettingsController>(SettingsController(audioPlayer),
        permanent: true); // Updated

    // Lazy-loaded controllers and services
    Get.lazyPut<FirebaseService>(() => FirebaseService(), fenix: true);
    Get.lazyPut<TaskController>(() => TaskController(), fenix: true);
    Get.lazyPut(() => PresenceService(), fenix: true);
    Get.lazyPut(() => ChatController(), fenix: true);
    Get.lazyPut(
      () => UserController(kDebugMode
          ? MockUserDeletionService()
          : CloudFunctionUserDeletionService()),
      fenix: true,
    );

    Get.lazyPut<ManageUsersController>(
      () => ManageUsersController(MockUserDeletionService()),
      fenix: true,
    );

    Get.lazyPut<NotificationController>(() => NotificationController(),
        fenix: true);
  }
}
