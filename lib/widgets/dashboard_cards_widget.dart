// widgets/dashboard_cards_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/utils/constants/app_strings.dart';
import 'package:task/utils/constants/app_styles.dart';
import '../../controllers/admin_controller.dart';

class DashboardCardsWidget extends StatelessWidget {
  final AdminController adminController;
  final VoidCallback onManageUsersTap;
  final ValueChanged<String?> onTaskSelected;

  const DashboardCardsWidget({
    super.key,
    required this.adminController,
    required this.onManageUsersTap,
    required this.onTaskSelected,
  });

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        _dashboardCard(
          title: AppStrings.totalUsers,
          value: adminController.totalUsers.value.toString(),
          onTap: onManageUsersTap,
          buttonText: AppStrings.manageUsers,
          textScale: textScaler.scale(1),
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _dashboardCard(
          title: AppStrings.totalTasks,
          value: adminController.totalTasks.value.toString(),
          dropdownItems: adminController.taskTitles,
          onDropdownChanged: onTaskSelected,
          selectedValue: adminController.selectedTaskTitle.value.isEmpty
              ? null
              : adminController.selectedTaskTitle.value,
          textScale: textScaler.scale(1),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _dashboardCard({
    required String title,
    required String value,
    double textScale = 1.0,
    VoidCallback? onTap,
    String? buttonText,
    List<String>? dropdownItems,
    ValueChanged<String?>? onDropdownChanged,
    String? selectedValue,
    required bool isDark,
  }) {
    final Color innerBg = isDark ? Colors.black : Colors.white;
    final Color innerText = isDark ? Colors.white : Colors.black;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppStyles.cardGradient,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: AppStyles.cardTitleStyle.copyWith(
                fontSize: 16 * textScale,
                color: innerText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppStyles.cardValueStyle.copyWith(
                fontSize: 28 * textScale,
                color: innerText,
              ),
            ),
            const SizedBox(height: 12),
            if (onTap != null && buttonText != null)
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  decoration: BoxDecoration(
                    color: innerBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    buttonText,
                    style:
                        TextStyle(fontSize: 14 * textScale, color: innerText),
                  ),
                ),
              ),
            if (dropdownItems != null && onDropdownChanged != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: innerBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Obx(() {
                  final sortedTasks = [...dropdownItems]..sort();
                  return DropdownButton<String>(
                    isExpanded: true,
                    value: selectedValue,
                    dropdownColor: innerBg,
                    hint: Text(
                      AppStrings.selectTask,
                      style: TextStyle(color: innerText),
                    ),
                    underline: const SizedBox(),
                    icon: Icon(Icons.arrow_drop_down, color: innerText),
                    items: sortedTasks
                        .map((title) => DropdownMenuItem<String>(
                              value: title,
                              child: Text(title,
                                  style: TextStyle(color: innerText)),
                            ))
                        .toList(),
                    onChanged: onDropdownChanged,
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}
