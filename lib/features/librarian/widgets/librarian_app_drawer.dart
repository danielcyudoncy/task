// features/librarian/widgets/librarian_app_drawer.dart
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/utils/constants/app_colors.dart';
import 'package:task/utils/devices/app_devices.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/controllers/theme_controller.dart';

class LibrarianAppDrawer extends StatefulWidget {
  const LibrarianAppDrawer({super.key});

  @override
  State<LibrarianAppDrawer> createState() => _LibrarianAppDrawerState();
}

class _LibrarianAppDrawerState extends State<LibrarianAppDrawer> {
  final authController = Get.find<AuthController>();
  bool _logoutHovered = false, _showCalendar = false;
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = AppDevices.getScreenHeight(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              height: 200.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [Colors.grey[900]!, Colors.grey[800]!]
                      : [
                          Theme.of(context).primaryColor,
                          AppColors.primaryColor,
                        ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: ConcentricCirclePainter(
                        centerOffset: Offset(70.w, 90.h),
                        ringColor: isDark ? Colors.white54 : Colors.white,
                        isDark: isDark,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 40.r,
                            backgroundColor: Colors.white,
                            backgroundImage: authController
                                    .profilePic.value.isNotEmpty
                                ? NetworkImage(authController.profilePic.value)
                                : null,
                            child: authController.profilePic.value.isEmpty
                                ? Text(
                                    authController.fullName.value.isNotEmpty
                                        ? authController.fullName.value[0]
                                            .toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 28.sp,
                                      fontFamily: 'Raleway',
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AutoSizeText(
                                authController.fullName.value,
                                style: TextStyle(
                                    fontSize: 20.sp,
                                    fontFamily: 'Raleway',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                                maxLines: 2,
                                minFontSize: 12,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                authController.currentUser?.email ?? '',
                                style: TextStyle(
                                    fontSize: 14.sp, color: Colors.white70),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Calendar toggle
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.calendar_today,
                    color:
                        _showCalendar ? Theme.of(context).primaryColor : null,
                  ),
                  title: Text(
                      _showCalendar ? 'Hide Calender'.tr : 'Show Calendar'.tr),
                  onTap: () {
                    Get.find<SettingsController>().triggerFeedback();
                    setState(() => _showCalendar = !_showCalendar);
                  },
                ),
              ),
            ),

            // Calendar view
            if (_showCalendar)
              Container(
                height: screenHeight * 0.45,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                child: SingleChildScrollView(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: TableCalendar(
                        firstDay:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          leftChevronIcon: Icon(Icons.chevron_left),
                          rightChevronIcon: Icon(Icons.chevron_right),
                        ),
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Theme.of(context)
                                .primaryColor
                                .withAlpha((0.6 * 255).toInt()),
                            shape: BoxShape.circle,
                          ),
                        ),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() => _focusedDay = focusedDay);
                        },
                      ),
                    ),
                  ),
                ),
              ),

            // Navigation tiles
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                children: [
                  _drawerTile(Icons.person_outline, 'Profile', () {
                    Get.find<SettingsController>().triggerFeedback();
                    Get.back();
                    Get.toNamed('/profile');
                  }),
                  _drawerTile(Icons.settings_outlined, 'Settings', () {
                    Get.find<SettingsController>().triggerFeedback();
                    Get.back();
                    Get.toNamed('/settings');
                  }),
                  _drawerTile(Icons.build_outlined, 'Fix Notifications', () {
                    Get.find<SettingsController>().triggerFeedback();
                    Get.back();
                    Get.toNamed('/notification-fix');
                  }),
                  _buildDarkModeCard(isDark),
                ],
              ),
            ),

            // Logout button
            Padding(
              padding: EdgeInsets.all(16.w),
              child: MouseRegion(
                onEnter: (_) => setState(() => _logoutHovered = true),
                onExit: (_) => setState(() => _logoutHovered = false),
                child: Card(
                  elevation: 2,
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r)),
                  child: ListTile(
                    leading: AnimatedRotation(
                      turns: _logoutHovered ? .25 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(Icons.logout, color: Colors.red),
                    ),
                    title: Text(
                      'Logout',
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                    onTap: _confirmLogout,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(IconData icon, String label, VoidCallback onTap) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: ListTile(leading: Icon(icon), title: Text(label.tr), onTap: onTap),
    );
  }

  Widget _buildDarkModeCard(bool isDark) {
    final ThemeController themeController = Get.find<ThemeController>();
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Obx(() => SwitchListTile(
            title: Text('Dark Mode',
                style: TextStyle(
                    fontSize: 16.sp,
                    color: Theme.of(context).textTheme.bodyLarge?.color)),
            value: themeController.isDarkMode.value,
            onChanged: (value) {
              themeController.toggleTheme(value);
            },
          )),
    );
  }

  Future<void> _confirmLogout() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: Theme.of(Get.context!).colorScheme.surface,
        title: Center(
          child: Text(
            'Confirm Logout'.tr,
            style: TextStyle(
              color: Theme.of(Get.context!).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        content: Text(
          'Are you sure?'.tr,
          style: TextStyle(
            color: Theme.of(Get.context!)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.8),
            fontSize: 14.sp,
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              'cancel'.tr,
              style: TextStyle(
                color:
                    isDark ? Colors.white : Theme.of(Get.context!).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white
                  : Theme.of(Get.context!).colorScheme.error,
              foregroundColor: isDark ? Colors.black : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            onPressed: () => Get.back(result: true),
            child: Text(
              'logout'.tr,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await authController.signOut();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/login');
      });
    }
  }
}

class ConcentricCirclePainter extends CustomPainter {
  final Offset centerOffset;
  final Color ringColor;
  final bool isDark;

  ConcentricCirclePainter({
    required this.centerOffset,
    required this.ringColor,
    required this.isDark,
  });

  @override
  void paint(Canvas c, Size s) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final radii = [60.0.w, 100.0.w, 140.0.w];
    final alphas = [0.4, 0.25, 0.12];
    for (int i = 0; i < radii.length; i++) {
      paint.color = ringColor.withValues(alpha: alphas[i]);
      c.drawCircle(centerOffset, radii[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
