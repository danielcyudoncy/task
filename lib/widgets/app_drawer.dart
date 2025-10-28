// widgets/app_drawer.dart
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Added import
import 'package:task/controllers/settings_controller.dart';
import 'package:task/utils/constants/app_colors.dart';
import 'package:task/utils/devices/app_devices.dart';

import '../controllers/auth_controller.dart';
import 'package:task/controllers/theme_controller.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key, String? chatBackground});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final authController = Get.find<AuthController>();
  bool _logoutHovered = false, _showCalendar = false;
  DateTime _focusedDay = DateTime.now();
  bool _isNavigating = false;

  // Validate if the URL is a valid HTTP/HTTPS URL (from previous discussion)
  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (e) {
      debugPrint('Invalid URL format: $url, error: $e');
      return false;
    }
  }

  // Helper for initials fallback
  Widget _buildInitialsAvatar(double radius, String fullName) {
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.7,
          fontFamily: 'Raleway',
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = AppDevices.getScreenHeight(context);
    final isLandscape = AppDevices.isLandscapeOrientation(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              height: isLandscape ? screenHeight * 0.25 : 200.h,
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
                        centerOffset: Offset(70.w, isLandscape ? 45.h : 90.h),
                        ringColor: isDark ? Colors.white54 : Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(isLandscape ? 12.w : 16.w),
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
                          child: ClipOval(
                            child: SizedBox(
                              width: isLandscape ? 60.r : 80.r,
                              height: isLandscape ? 60.r : 80.r,
                              child: Obx(() {
                                // Make reactive to controller changes
                                final profilePic =
                                    authController.profilePic.value;
                                if (profilePic.isNotEmpty &&
                                    _isValidUrl(profilePic)) {
                                  return CachedNetworkImage(
                                    imageUrl: profilePic,
                                    placeholder: (context, url) =>
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                    errorWidget: (context, url, error) {
                                      debugPrint(
                                          'Profile image error: $error for URL: $url');
                                      return _buildInitialsAvatar(
                                        isLandscape ? 30.r : 40.r,
                                        authController.fullName.value,
                                      );
                                    },
                                    imageBuilder: (context, imageProvider) =>
                                        CircleAvatar(
                                      radius: isLandscape ? 30.r : 40.r,
                                      backgroundImage: imageProvider,
                                      backgroundColor: Colors.white,
                                    ),
                                  );
                                } else {
                                  return _buildInitialsAvatar(
                                    isLandscape ? 30.r : 40.r,
                                    authController.fullName.value,
                                  );
                                }
                              }),
                            ),
                          ),
                        ),
                        SizedBox(width: isLandscape ? 12.w : 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AutoSizeText(
                                authController.fullName.value,
                                style: TextStyle(
                                    fontSize: isLandscape ? 16.sp : 20.sp,
                                    fontFamily: 'Raleway',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                                maxLines: 2,
                                minFontSize: 12,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: isLandscape ? 2.h : 4.h),
                              Text(
                                authController.currentUser?.email ?? '',
                                style: TextStyle(
                                    fontSize: isLandscape ? 12.sp : 10.sp,
                                    color: Colors.white70),
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

            // Calendar toggle (unchanged)
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
                      _showCalendar ? 'Hide Calendar'.tr : 'Show Calendar'.tr),
                  onTap: () {
                    Get.find<SettingsController>().triggerFeedback();
                    setState(() => _showCalendar = !_showCalendar);
                  },
                ),
              ),
            ),

            // Calendar view (unchanged)
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

            // Navigation tiles (unchanged)
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                children: [
                  _drawerTile(Icons.home_outlined, 'Home', () async {
                    if (_isNavigating) return;
                    Get.find<SettingsController>().triggerFeedback();
                    setState(() => _isNavigating = true);
                    Navigator.of(context).pop();
                    await Future.delayed(const Duration(milliseconds: 300));
                    try {
                      final currentRoute = Get.currentRoute;
                      if (currentRoute != '/admin-dashboard') {
                        await Get.offNamed('/admin-dashboard');
                      }
                    } catch (e) {
                      Get.offAllNamed('/login');
                    } finally {
                      if (mounted) {
                        setState(() => _isNavigating = false);
                      }
                    }
                  }),
                  _drawerTile(Icons.person_outline, 'Profile', () {
                    Get.find<SettingsController>().triggerFeedback();
                    Get.back();
                    Get.toNamed('/profile');
                  }),
                  _drawerTile(Icons.chat_outlined, 'Chat Users', () async {
                    if (_isNavigating) return;
                    Get.find<SettingsController>().triggerFeedback();
                    setState(() => _isNavigating = true);
                    Navigator.of(context).pop();
                    await Future.delayed(const Duration(milliseconds: 200));
                    try {
                      await Get.toNamed('/all-users-chat');
                    } catch (e) {
                      Get.snackbar("Error", "Could not open chat");
                    } finally {
                      if (mounted) {
                        setState(() => _isNavigating = false);
                      }
                    }
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

            // Logout button (unchanged)
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
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  size: 18.sp,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Theme',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Obx(() => _buildCompactThemeOptions(themeController)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactThemeOptions(ThemeController themeController) {
    return Row(
      children: AppThemeMode.values.map((mode) {
        final isSelected = themeController.currentThemeMode.value == mode;
        return Expanded(
          child: GestureDetector(
            onTap: () => themeController.setThemeMode(mode),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 2.w),
              padding: EdgeInsets.symmetric(vertical: 8.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _getThemeIcon(mode),
                    size: 16.sp,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    mode.displayName,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getThemeIcon(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return Icons.light_mode_outlined;
      case AppThemeMode.dark:
        return Icons.dark_mode_outlined;
      case AppThemeMode.system:
        return Icons.settings_system_daydream_outlined;
    }
  }

  Future<void> _confirmLogout() async {
    final isDark = Theme.of(Get.context!).brightness == Brightness.dark;

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

  ConcentricCirclePainter(
      {required this.centerOffset, required this.ringColor});

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
