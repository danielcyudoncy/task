// views/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';
import '../controllers/auth_controller.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminController adminController = Get.find<AdminController>();
  final AuthController authController = Get.find<AuthController>();
  final RxInt selectedTab = 0.obs;

  @override
  void initState() {
    super.initState();
    adminController.fetchStatistics();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (adminController.isLoading.value ||
          adminController.isStatsLoading.value) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Color(0xFF0B189B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Welcome, Name, Avatar, Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Welcome, Avatar, Name
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage:
                                NetworkImage(authController.profilePic.value),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Welcome',
                                  style: TextStyle(fontSize: 14)),
                              Text(
                                authController.fullName.value,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Camera & Logout
                      Row(
                        children: [
                          _iconButton(Icons.camera_alt, () {
                            // Implement camera logic
                          }),
                          const SizedBox(width: 10),
                          _iconButton(Icons.logout, () {
                            authController.logout();
                          }),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Daily Assignments Text
                  const Text(
                    'DAILY ASSIGNMENTS',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo),
                  ),
                  const SizedBox(height: 12),

                  // Clickable Stats
                  Row(
                    children: [
                      _statCard(
                        label: 'Total Users',
                        value: adminController.totalUsers.value.toString(),
                        onTap: () => Get.toNamed('/users-list'),
                      ),
                      const SizedBox(width: 12),
                      _statCard(
                        label: 'Total Task',
                        value: adminController.totalTasks.value.toString(),
                        onTap: () => Get.toNamed('/tasks-list'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // TASK & Create Task Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TASK',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.toNamed('/task-creation'),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0B189B),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Tab Switcher
                  Obx(() {
                    return Row(
                      children: [
                        _tabButton('Not Completed', 0),
                        _tabButton('Completed', 1),
                      ],
                    );
                  }),

                  const SizedBox(height: 16),

                  // Task List
                  Expanded(
                    child: Obx(() {
                      bool showCompleted = selectedTab.value == 1;
                      return ListView.builder(
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          return _taskCard(
                            title: 'Task ${index + 1}',
                            completed: showCompleted,
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(color: const Color(0xFF0B189B), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF0B189B), size: 20),
      ),
    );
  }

  Widget _statCard(
      {required String label,
      required String value,
      required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF6773EC), Color(0xFF3A49D9)],
            ),
          ),
          child: Column(
            children: [
              Text(label, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String title, int index) {
    return Expanded(
      child: GestureDetector(
        onTap: () => selectedTab.value = index,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selectedTab.value == index
                    ? const Color(0xFF0B189B)
                    : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selectedTab.value == index
                  ? const Color(0xFF0B189B)
                  : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _taskCard({required String title, required bool completed}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B189B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.task, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          Icon(
            completed ? Icons.check_circle : Icons.pending,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}
