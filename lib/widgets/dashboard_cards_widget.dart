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
    return Row(
      children: [
        _dashboardCard(
          title: AppStrings.totalUsers,
          value: adminController.totalUsers.value.toString(),
          onTap: onManageUsersTap,
          buttonText: AppStrings.manageUsers,
        ),
        const SizedBox(width: 12),
        _dashboardCard(
          title: AppStrings.totalTasks,
          value: adminController.totalTasks.value.toString(),
          dropdownItems: adminController.taskTitles,
          onDropdownChanged: onTaskSelected,
        ),
      ],
    );
  }

  Widget _dashboardCard({
    required String title,
    required String value,
    VoidCallback? onTap,
    String? buttonText,
    List<String>? dropdownItems,
    ValueChanged<String?>? onDropdownChanged,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppStyles.cardGradient,
        ),
        child: Column(
          children: [
            Text(title, style: AppStyles.cardTitleStyle),
            const SizedBox(height: 6),
            Text(value, style: AppStyles.cardValueStyle),
            const SizedBox(height: 12),
            if (onTap != null && buttonText != null)
              GestureDetector(
                onTap: onTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(buttonText,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black)),
                ),
              ),
            if (dropdownItems != null && onDropdownChanged != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Obx(() {
                  final sortedTasks = [...dropdownItems]..sort();
                  return DropdownButton<String>(
                    isExpanded: true,
                    value: adminController.selectedTaskTitle.value.isEmpty
                        ? null
                        : adminController.selectedTaskTitle.value,
                    hint: const Text(AppStrings.selectTask),
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down),
                    items: sortedTasks
                        .map((title) => DropdownMenuItem<String>(
                              value: title,
                              child: Text(title),
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
