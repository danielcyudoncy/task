// widgets/stat_card.dart
import 'package:flutter/material.dart';
import 'package:task/utils/constants/app_colors.dart';
import 'package:task/utils/constants/app_styles.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget statCard({
  IconData? icon,
  Widget? iconWidget,
  required String label,
  required String value,
  required Color color,
}) =>
    Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 100.h),
      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: AppColors.saveColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          iconWidget ?? Icon(icon, color: color, size: 32.sp),
          const SizedBox(height: 8),
          Text(label, style: AppStyles.cardTitleStyle),
          Text(value, style: AppStyles.cardValueStyle),
        ],
      ),
    );
