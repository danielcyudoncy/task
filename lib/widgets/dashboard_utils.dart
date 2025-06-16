// widgets/dashboard_utils.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Helpers for formatting and UI logic

String formatDueDate(dynamic dueDate) {
  if (dueDate == null) return "Not set";
  if (dueDate is Timestamp) {
    final dt = dueDate.toDate();
    return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
  }
  if (dueDate is DateTime) {
    return "${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}";
  }
  if (dueDate is String && dueDate.isNotEmpty) {
    try {
      final dt = DateTime.parse(dueDate);
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    } catch (e) {
      return dueDate;
    }
  }
  return "Not set";
}

String getCreatorInitials(Map<String, dynamic> task) {
  final creator = (task['creatorName'] ?? task['creator'] ?? "").trim();
  if (creator.isEmpty) return "?";
  final parts = creator.split(" ");
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return (parts[0][0] + parts.last[0]).toUpperCase();
}

Color getPriorityColor(Map<String, dynamic> task) {
  final priority = (task['priority'] ?? '').toString().toLowerCase();
  switch (priority) {
    case 'high':
      return Colors.redAccent;
    case 'medium':
      return Colors.orangeAccent;
    case 'low':
      return Colors.green;
    default:
      return Colors.blueGrey;
  }
}

IconData getStatusIcon(Map<String, dynamic> task) {
  final status = (task['status'] ?? '').toString().toLowerCase();
  switch (status) {
    case 'pending':
      return Icons.schedule;
    case 'in progress':
      return Icons.autorenew;
    case 'review':
      return Icons.visibility;
    case 'completed':
      return Icons.check_circle_outline;
    default:
      return Icons.radio_button_unchecked;
  }
}

Color getBorderColor(ThemeData theme, bool isDark, Color primaryBlue) {
  if (isDark) return Colors.white24;
  return Color.lerp(primaryBlue, Colors.white, 0.8) ?? primaryBlue;
}
