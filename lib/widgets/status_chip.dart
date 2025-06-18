// widgets/status_chip.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final double textScale;

  const StatusChip({required this.status, required this.textScale, super.key});

  @override
  Widget build(BuildContext context) {
    Color chipColor;
    Color textColor = Colors.white;
    switch (status.toLowerCase()) {
      case "completed":
        chipColor = Colors.green;
        break;
      case "pending":
        chipColor = Colors.orange;
        break;
      case "overdue":
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
        textColor = Colors.black;
        break;
    }
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Chip(
        label: Text(
          status,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontFamily: 'raleway',
            fontSize: 12.sp * textScale,
          ),
        ),
        backgroundColor: chipColor,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      ),
    );
  }
}