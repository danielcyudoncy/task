// widgets/theme_selector_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/theme_controller.dart';

class ThemeSelectorWidget extends StatelessWidget {
  final String? title;
  final String? subtitle;
  
  const ThemeSelectorWidget({
    super.key,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.palette_outlined,
                    size: 20.sp,
                    color: colorScheme.primary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                SizedBox(height: 4.h),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
              SizedBox(height: 16.h),
            ],
            Obx(() => Column(
              children: AppThemeMode.values.map((mode) {
                final isSelected = themeController.currentThemeMode.value == mode;
                return _buildThemeOption(
                  context,
                  mode,
                  isSelected,
                  () => themeController.setThemeMode(mode),
                );
              }).toList(),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    AppThemeMode mode,
    bool isSelected,
    VoidCallback onTap,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final ThemeController themeController = Get.find<ThemeController>();

    IconData getIcon() {
      switch (mode) {
        case AppThemeMode.light:
          return Icons.light_mode_outlined;
        case AppThemeMode.dark:
          return Icons.dark_mode_outlined;
        case AppThemeMode.system:
          return Icons.settings_system_daydream_outlined;
      }
    }

    String getDescription() {
      switch (mode) {
        case AppThemeMode.light:
          return 'Always use light theme';
        case AppThemeMode.dark:
          return 'Always use dark theme';
        case AppThemeMode.system:
          return 'Follow system settings';
      }
    }

    String getSystemStatus() {
      if (mode == AppThemeMode.system) {
        return themeController.isSystemDark.value ? ' (Currently Dark)' : ' (Currently Light)';
      }
      return '';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isSelected 
                  ? colorScheme.primary.withValues(alpha: 0.1) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: isSelected 
                    ? colorScheme.primary.withValues(alpha: 0.3)
                    : colorScheme.outline.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Icon(
                    getIcon(),
                    size: 18.sp,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.primary,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            mode.displayName,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                            ),
                          ),
                          if (mode == AppThemeMode.system)
                            Obx(() => Text(
                              getSystemStatus(),
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w400,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            )),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        getDescription(),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      size: 14.sp,
                      color: colorScheme.onPrimary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
