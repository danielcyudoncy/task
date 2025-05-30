// views/home_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/widgets/user_nav_bar.dart';
import '../controllers/notification_controller.dart';
import '../controllers/auth_controller.dart';


class HomeScreen extends StatelessWidget {
  final NotificationController notificationController =
      Get.put(NotificationController(), permanent: true);
  final AuthController authController = Get.find<AuthController>();

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
              authController.fullName.value.isNotEmpty
                  ? "Welcome, ${authController.fullName.value}!"
                  : "Assignment Logging App",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            )),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Obx(() => Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        Get.toNamed("/notifications");
                      },
                    ),
                    if (notificationController.unreadCount.value > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '${notificationController.unreadCount.value}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                )),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Welcome to the Assignment Logging App!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Obx(() {
              if (authController.fullName.value.isNotEmpty) {
                // Show task-related buttons only when logged in (fullName is not empty)
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => Get.toNamed("/task-creation"),
                          child: const Text("Create Task"),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => Get.toNamed("/task-list"),
                          child: const Text("View Tasks"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Since you don't have signOut(), you might need to implement this
                        // or navigate to a logout screen
                        // For now, we'll just navigate to login
                        Get.offAllNamed("/login");
                      },
                      child: const Text("Logout"),
                    ),
                  ],
                );
              } else {
                // Show login button when not logged in (fullName is empty)
                return ElevatedButton(
                  onPressed: () {
                    Get.toNamed("/login");
                  },
                  child: const Text("Login"),
                );
              }
            }),
          ],
        ),
      ),
      bottomNavigationBar:
          const UserNavBar(currentIndex: 0), // <-- Add this line
    );
  }
}
