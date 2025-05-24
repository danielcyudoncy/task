// views/profile_scren.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Obx(() {
          final fullName = authController.fullName.value;
          final profilePicUrl = authController.profilePic.value;
          final phone = authController.userData['phoneNumber'] ?? '';
          final email = authController.currentUser?.email ?? '';

          if (authController.currentUser == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Home Icon
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, left: 16.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: const Color(0xFF3739B7)),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.home_outlined,
                            color: Color(0xFF3739B7)),
                        onPressed: () {
                          // Navigate to the user's home screen based on their role
                          final role = authController.userRole.value;
                          if (role == "Admin" ||
                              role == "Assignment Editor" ||
                              role == "Head of Department") {
                            Get.offAllNamed('/admin-dashboard');
                          } else if (role == "Reporter" ||
                              role == "Cameraman") {
                            Get.offAllNamed('/home');
                          } else {
                            // Default/fallback route
                            Get.offAllNamed('/login');
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: profilePicUrl.isNotEmpty
                        ? Image.network(
                            profilePicUrl,
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: Colors.grey[300],
                              width: 140,
                              height: 140,
                              child: Icon(Icons.person,
                                  size: 72, color: Colors.grey[600]),
                            ),
                          )
                        : Container(
                            color: Colors.grey[300],
                            width: 140,
                            height: 140,
                            child: Icon(Icons.person,
                                size: 72, color: Colors.grey[600]),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF3739B7),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 24),
                // Card with Info and Profile Actions
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 24,
                        offset: Offset(0, 9),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Contact Information
                      Text(
                        "CONTACT INFORMATION",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[700],
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.phone,
                              size: 19, color: Color(0xFF3739B7)),
                          const SizedBox(width: 10),
                          Text(phone, style: const TextStyle(fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.email,
                              size: 19, color: Color(0xFF3739B7)),
                          const SizedBox(width: 10),
                          Text(email, style: const TextStyle(fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Profile Section
                      Text(
                        "PROFILE",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[700],
                          letterSpacing: 0.2,
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.notifications_none,
                            color: Color(0xFF3739B7)),
                        title: const Text("Push Notifications"),
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: Colors.grey[600]),
                        onTap: () {
                          // Navigate to notifications settings
                          Get.toNamed('/push-notification-settings');
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_outline,
                            color: Color(0xFF3739B7)),
                        title: const Text("Update Profile"),
                        trailing: Icon(Icons.chevron_right_rounded,
                            color: Colors.grey[600]),
                        onTap: () {
                          // Navigate to update profile
                          Get.toNamed('/profile-update');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3739B7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: const Text("Log out",
                              style: TextStyle(fontSize: 18)),
                          onPressed: () {
                            authController.signOut();
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3739B7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          icon: const Icon(Icons.delete_forever,
                              color: Colors.white),
                          label: const Text("Delete Account",
                              style: TextStyle(fontSize: 18)),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Account'),
                                content: const Text(
                                    'Are you sure you want to delete your account? This action cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              authController.deleteAccount();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }),
      ),
    );
  }
}
