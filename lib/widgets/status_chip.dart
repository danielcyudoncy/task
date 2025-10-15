// widgets/status_chip.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final double textScale;

  const StatusChip({required this.status, required this.textScale, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color chipColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case "completed":
        chipColor = isDark ? Colors.green[700]! : Colors.green[100]!;
        textColor = isDark ? Colors.green[100]! : Colors.green[800]!;
        break;
      case "pending":
        chipColor = isDark ? Colors.orange[700]! : Colors.orange[100]!;
        textColor = isDark ? Colors.orange[100]! : Colors.orange[800]!;
        break;
      case "overdue":
        chipColor = isDark ? Colors.red[700]! : Colors.red[100]!;
        textColor = isDark ? Colors.red[100]! : Colors.red[800]!;
        break;
      default:
        chipColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
        textColor = isDark ? Colors.grey[100]! : Colors.grey[800]!;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontFamily: 'raleway',
            fontSize: 12.sp * textScale,
          ),
        ),
      ),
    );
  }
}
