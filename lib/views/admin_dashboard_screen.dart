// views/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/admin_controller.dart';

class AdminDashboardScreen extends StatelessWidget {
  AdminDashboardScreen({super.key});

  final AdminController adminController = Get.find<AdminController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        centerTitle: true,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // ✅ Admin Profile Picture & Name
            Center(
              child: Column(
                children: [
                  Obx(
                    () => CircleAvatar(
                      radius: 50,
                      backgroundImage: adminController
                              .adminPhotoUrl.value.isNotEmpty
                          ? NetworkImage(adminController.adminPhotoUrl.value)
                          : const AssetImage("assets/default_avatar.png")
                              as ImageProvider,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Obx(
                    () => Text(
                      adminController.adminName.value.isNotEmpty
                          ? adminController.adminName.value
                          : "Admin",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ✅ Statistics Cards (Real-time updates)
            Obx(() {
              if (adminController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildStatCard(
                    title: "Total Users",
                    count: adminController.totalUsers.value,
                    icon: LucideIcons.users,
                    color: Colors.blue.shade600,
                    onTap: () => _showDetailsDialog(
                        "Total Users", adminController.userNames),
                  ),
                  _buildStatCard(
                    title: "Total Tasks",
                    count: adminController.totalTasks.value,
                    icon: LucideIcons.fileText,
                    color: Colors.green.shade600,
                    onTap: () => _showDetailsDialog(
                        "Total Tasks", adminController.taskTitles),
                  ),
                  _buildStatCard(
                    title: "Completed Tasks",
                    count: adminController.completedTasks.value,
                    icon: LucideIcons.checkCircle2,
                    color: Colors.orange.shade600,
                    onTap: () => _showDetailsDialog(
                        "Completed Tasks", adminController.completedTaskTitles),
                  ),
                  _buildStatCard(
                    title: "Pending Tasks",
                    count: adminController.pendingTasks.value,
                    icon: LucideIcons.clock,
                    color: Colors.red.shade600,
                    onTap: () => _showDetailsDialog(
                        "Pending Tasks", adminController.pendingTaskTitles),
                  ),
                ],
              );
            }),

            const SizedBox(height: 24),

            // ✅ Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  label: "Manage Users",
                  icon: LucideIcons.userCog,
                  onPressed: () => Get.toNamed("/manage-users"),
                ),
                _buildActionButton(
                  label: "View Reports",
                  icon: LucideIcons.fileBarChart,
                  onPressed: () => Get.toNamed("/reports"),
                ),
              ],
            ),

            const SizedBox(height: 80),

            // ✅ Logout Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.black),
                ),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: _logout,
              icon:
                  const Icon(LucideIcons.logOut, size: 20, color: Colors.black),
              label:
                  const Text("Logout", style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Logout Function
  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Get.offAllNamed("/login");
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to logout. Try again.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // ✅ Builds Stat Cards
  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 10),
              Text(
                "$count",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Pop-up Dialog for Showing Details
  void _showDetailsDialog(String title, RxList<String> items) {
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Obx(
            () => items.isEmpty
                ? const Center(child: Text("No data available"))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(items[index]),
                      );
                    },
                  ),
          ),
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

  // ✅ Builds Action Buttons
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }
}
