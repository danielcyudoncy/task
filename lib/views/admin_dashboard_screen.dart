// views/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../controllers/admin_controller.dart';
import '../controllers/auth_controller.dart';

class AdminDashboardScreen extends StatelessWidget {
  AdminDashboardScreen({super.key});
  final AdminController adminController = Get.find<AdminController>();
  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (adminController.isLoading.value) {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
      if (authController.userRole.value != "Admin") {
        Future.microtask(() => Get.offAllNamed("/login"));
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

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
              _buildAdminProfileSection(),
              const SizedBox(height: 20),
              _buildStatisticsSection(),
              const SizedBox(height: 24),
              _buildActionButtonsSection(),
              const SizedBox(height: 80),
              _buildLogoutButton(),
            ],
          ),
        ),
      );
    });
  }

  // Admin Profile Section
  Widget _buildAdminProfileSection() {
    return Center(
      child: Column(
        children: [
          Obx(
            () => CircleAvatar(
              radius: 50,
              backgroundImage: adminController.adminPhotoUrl.value.isNotEmpty
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
    );
  }

  // Statistics Section
  Widget _buildStatisticsSection() {
    return Obx(() {
      if (adminController.isStatsLoading.value) {
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
              "Total Users",
              adminController.userNames.toList(),
            ),
          ),
          _buildStatCard(
            title: "Total Tasks",
            count: adminController.totalTasks.value,
            icon: LucideIcons.fileText,
            color: Colors.green.shade600,
            onTap: () => _showDetailsDialog(
              "Total Tasks",
              adminController.taskTitles.toList(),
            ),
          ),
          _buildStatCard(
            title: "Completed Tasks",
            count: adminController.completedTasks.value,
            icon: LucideIcons.checkCircle2,
            color: Colors.orange.shade600,
            onTap: () => _showDetailsDialog(
              "Completed Tasks",
              adminController.completedTaskTitles.toList(),
            ),
          ),
          _buildStatCard(
            title: "Pending Tasks",
            count: adminController.pendingTasks.value,
            icon: LucideIcons.clock,
            color: Colors.red.shade600,
            onTap: () => _showDetailsDialog(
              "Pending Tasks",
              adminController.pendingTaskTitles.toList(),
            ),
          ),
        ],
      );
    });
  }

  // Action Buttons Section
  Widget _buildActionButtonsSection() {
    return Row(
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
    );
  }

  // Logout Button Section
  Widget _buildLogoutButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.black),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      onPressed: () async {
        await adminController.logout();
      },
      icon: const Icon(LucideIcons.logOut),
      label: const Text("Logout"),
    );
  }

  // Reusable Statistic Card
  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 10),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Reusable Action Button
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }

  // Details Dialog for Viewing Items
  void _showDetailsDialog(String title, List<String> items) {
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(items[index]),
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
}
