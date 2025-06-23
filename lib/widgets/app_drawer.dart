// widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';

class AppDrawer extends StatelessWidget {
  final authController = Get.find<AuthController>();

  AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color selectedColor = isDark
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).primaryColor;

    Widget drawerItem({
      required IconData icon,
      required String label,
      required String route,
    }) {
      final isSelected = currentRoute == route;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color:
            isSelected ? selectedColor.withOpacity(0.15) : Colors.transparent,
        child: ListTile(
          leading: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              icon,
              key: ValueKey<bool>(isSelected),
              color: isSelected ? selectedColor : null,
            ),
          ),
          title: Text(
            label,
            style: TextStyle(
              color: isSelected ? selectedColor : null,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          onTap: () {
            Navigator.pop(context);
            if (!isSelected) Get.toNamed(route);
          },
        ),
      );
    }

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            currentAccountPicture: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              backgroundImage: authController.profilePic.value.isNotEmpty
                  ? NetworkImage(authController.profilePic.value)
                  : null,
              child: authController.profilePic.value.isEmpty
                  ? Text(
                      authController.fullName.value.isNotEmpty
                          ? authController.fullName.value[0].toUpperCase()
                          : '?',
                      style:  TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF08169D),
                        fontFamily: 'Raleway',
                      ),
                    )
                  : null,
            ),
            accountName: Text(
              authController.fullName.value.isNotEmpty
                  ? authController.fullName.value
                  : 'User',
              style:  TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
                color: Colors.white,
                fontFamily: 'Raleway',
              ),
            ),
            accountEmail: Text(
              authController.currentUser?.email ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.grey.shade900, Colors.black87]
                    : [Theme.of(context).primaryColor, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),



          drawerItem(icon: Icons.home, label: 'Home', route: '/home'),
          drawerItem(icon: Icons.person, label: 'Profile', route: '/profile'),
          drawerItem(
              icon: Icons.settings, label: 'Settings', route: '/settings'),
          drawerItem(
              icon: Icons.list_alt, label: 'All Tasks', route: '/all-tasks'),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await authController.signOut();
            },
          ),
        ],
      ),
    );
  }
}
