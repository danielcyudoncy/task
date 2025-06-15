// widgets/dashboard_cards_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
      ),
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
        constraints: BoxConstraints(minHeight: 180.h), // Set a minimum height
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppStyles.cardGradient,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                title,
                style: AppStyles.cardTitleStyle.copyWith(
                  fontSize: 16.sp * textScale,
                  color: innerText,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                value,
                style: AppStyles.cardValueStyle.copyWith(
                  fontSize: 28.sp * textScale,
                  color: innerText,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (onTap != null && buttonText != null)
              Center(
                child: Container(
                  height: 50.h, // <-- Fixed height
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: innerBg,
                      foregroundColor: innerText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.zero,
                      elevation: 0,
                    ),
                    child: Text(
                      buttonText,
                      style: TextStyle(
                          fontSize: 14.sp * textScale, color: innerText),
                    ),
                  ),
                ),
              ),
            if (dropdownItems != null && onDropdownChanged != null)
              Center(
                child: Container(
                  height: 50.h, // Matches button height
                  
                  
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12), // More padding for better look
                  decoration: BoxDecoration(
                    color: innerBg, // Match your app's card/button background
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: innerText.withOpacity(0.15), // Subtle border
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Text(
                        "${AppStrings.selectTask}: ",
                        style: TextStyle(
                          color: innerText,
                          fontWeight: FontWeight.w500,
                          fontSize: 14.sp * textScale,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedValue,
                            dropdownColor: innerBg,
                            hint: Text(
                              AppStrings.selectTask,
                              style:
                                  TextStyle(color: innerText.withOpacity(0.7)),
                            ),
                            icon: Icon(Icons.arrow_drop_down, color: innerText),
                            style: TextStyle(
                              color: innerText,
                              fontSize: 14.sp * textScale,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            items: dropdownItems.map((title) {
                              return DropdownMenuItem<String>(
                                value: title,
                                child: Text(title,
                                    style: TextStyle(color: innerText)),
                              );
                            }).toList(),
                            onChanged: onDropdownChanged,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
