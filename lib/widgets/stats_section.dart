// widgets/stats_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/task_controller.dart';
import '../../utils/constants/app_colors.dart';
import '../../utils/constants/app_strings.dart';
import '../../utils/constants/app_styles.dart';

class StatsSection extends StatelessWidget {
  final TaskController taskController;
  final bool isDark;

  const StatsSection({
    super.key,
    required this.taskController,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint("StatsSection: Building widget");
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Obx(() {
              debugPrint("StatsSection: Building Obx widget");
              if (!Get.isRegistered<TaskController>()) {
                debugPrint("StatsSection: TaskController not registered");
                return _statCard(
                  icon: Icons.create,
                  label: AppStrings.taskCreated,
                  value: "0",
                  color: isDark ? Colors.white : AppColors.secondaryColor,
                );
              }
              
              try {
                final totalTasks = taskController.totalTaskCreated.value;
                debugPrint("StatsSection: Total tasks: $totalTasks");
                return _statCard(
                  icon: Icons.create,
                  label: AppStrings.taskCreated,
                  value: totalTasks.toString(),
                  color: isDark ? Colors.white : AppColors.secondaryColor,
                );
              } catch (e) {
                debugPrint("StatsSection: Error getting total tasks: $e");
                return _statCard(
                  icon: Icons.create,
                  label: AppStrings.taskCreated,
                  value: "0",
                  color: isDark ? Colors.white : AppColors.secondaryColor,
                );
              }
            }),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Get.toNamed('/news');
              },
              child: _statCard(
                iconWidget: _buildNewsFeedIcon(),
                icon: Icons.rss_feed,
                label: "News Feed",
                value: "", // No value shown
                color: isDark
                    ? const Color(0xFF9FA8DA)
                    : AppColors.secondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsFeedIcon() {
    return Stack(
      children: [
        Icon(
          Icons.rss_feed,
          color: isDark ? Colors.white : AppColors.secondaryColor,
          size: 32,
        ),
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            constraints: BoxConstraints(
              minWidth: 16.w,
              minHeight: 16.h,
            ),
            child: Text(
              "3",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    IconData? icon,
    Widget? iconWidget,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 100),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.saveColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          iconWidget ?? Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(label, style: AppStyles.cardTitleStyle),
          Text(value, style: AppStyles.cardValueStyle),
        ],
      ),
    );
  }
}
