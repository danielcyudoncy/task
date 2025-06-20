// widgets/stat_card.dart
import 'package:flutter/material.dart';
import 'package:task/utils/constants/app_colors.dart';
import 'package:task/utils/constants/app_styles.dart';

Widget statCard({
  IconData? icon,
  Widget? iconWidget,
  required String label,
  required String value,
  required Color color,
}) =>
    Container(
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
