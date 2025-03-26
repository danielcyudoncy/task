import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/user_controller.dart';
import '../controllers/task_controller.dart';
import '../controllers/auth_controller.dart';

class AdminDashboardScreen extends StatelessWidget {
  final UserController userController = Get.put(UserController());
  final TaskController taskController = Get.put(TaskController());
  final AuthController authController = Get.find<AuthController>();

  final RxBool isClicked = false.obs; // ✅ Track Card Click State

  AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // ✅ Removes back icon
        title: Row(
          children: [
            // ✅ Display Admin Profile Picture
            Obx(() {
              return CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[300],
                backgroundImage: authController.profilePic.value.isNotEmpty
                    ? NetworkImage(authController.profilePic.value)
                    : null,
                child: authController.profilePic.value.isEmpty
                    ? const Icon(Icons.person, size: 30, color: Colors.white)
                    : null,
              );
            }),
            const SizedBox(width: 10),

            // ✅ Display Admin Name
            Obx(() => Text(
                  authController.fullName.value.isNotEmpty
                      ? authController.fullName.value
                      : "Admin",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                )),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              authController.logout();
              Get.offAllNamed("/login"); // ✅ Redirect to Login Screen
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Overview Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => _buildClickableCard(
                      "Total Users",
                      userController.allUsers.length.toString(),
                      Icons.people,
                      () => _handleCardClick(context),
                      isClicked.value,
                    )),
                Obx(() => _buildInfoCard(
                      "Total Tasks",
                      taskController.tasks.length.toString(),
                      Icons.task,
                    )),
              ],
            ),

            const SizedBox(height: 20),

            // ✅ List of Authenticated Users
            const Text(
              "Authenticated Users",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Obx(() {
                if (userController.allUsers.isEmpty) {
                  return const Center(child: Text("No users found"));
                }
                return ListView.builder(
                  itemCount: userController.allUsers.length,
                  itemBuilder: (context, index) {
                    var user = userController.allUsers[index];
                    return Card(
                      child: ListTile(
                        title: Text(user["name"]),
                        subtitle: Text("Role: ${user["role"]}"),
                      ),
                    );
                  },
                );
              }),
            ),

            const SizedBox(height: 10),

            // ✅ List of Created Tasks
            const Text(
              "All Created Tasks",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Obx(() {
                if (taskController.tasks.isEmpty) {
                  return const Center(child: Text("No tasks available"));
                }
                return ListView.builder(
                  itemCount: taskController.tasks.length,
                  itemBuilder: (context, index) {
                    var task = taskController.tasks[index];
                    return Card(
                      child: ListTile(
                        title: Text(task.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Created by: ${task.createdBy}"),
                            Text("Assigned to Reporter: ${task.assignedReporter ?? "Not Assigned"}"),
                            Text("Assigned to Cameraman: ${task.assignedCameraman ?? "Not Assigned"}"),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Clickable "Total Users" Card with Color Change
  Widget _buildClickableCard(String title, String value, IconData icon, VoidCallback onTap, bool clicked) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 4,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: clicked ? Colors.blue[400] : Colors.blue[100], // ✅ Changes color when clicked
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: Colors.blue),
                const SizedBox(height: 10),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Normal Info Card for Total Tasks
  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blue),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Handle Click: Toggle Color & Show Dialog
  void _handleCardClick(BuildContext context) {
    isClicked.value = !isClicked.value;
    _showUsersDialog(context);
  }

  // ✅ Show Dialog with List of Authenticated Users
  void _showUsersDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text("Authenticated Users"),
        content: SizedBox(
          width: double.maxFinite,
          child: Obx(() {
            if (userController.allUsers.isEmpty) {
              return const Center(child: Text("No users found"));
            }
            return ListView.builder(
              shrinkWrap: true,
              itemCount: userController.allUsers.length,
              itemBuilder: (context, index) {
                var user = userController.allUsers[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(user["name"]),
                  subtitle: Text("Role: ${user["role"]}"),
                );
              },
            );
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}
