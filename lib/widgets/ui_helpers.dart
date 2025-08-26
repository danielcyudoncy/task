import 'package:flutter/material.dart';

class UIHelpers {
  /// Builds an empty state icon with consistent styling
  static Widget buildEmptyStateIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  /// Gets color based on task status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF39C12);
      case 'approved':
        return const Color(0xFF27AE60);
      case 'rejected':
        return const Color(0xFFE74C3C);
      case 'in_progress':
        return const Color(0xFF3498DB);
      case 'completed':
        return const Color(0xFF9B59B6);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  /// Gets color based on task priority
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFE74C3C);
      case 'medium':
        return const Color(0xFFF39C12);
      case 'low':
        return const Color(0xFF27AE60);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  /// Builds a consistent section container
  static Widget buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Widget content,
    Color? iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF34495E)
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (iconColor ?? const Color(0xFF4A90E2)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? const Color(0xFF4A90E2),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  /// Builds a detail row for displaying key-value pairs
  static Widget buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a tag widget
  static Widget buildTag(BuildContext context, String tag, {Color? color}) {
    final tagColor = color ?? const Color(0xFF4A90E2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: tagColor.withOpacity(0.3),
        ),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 12,
          color: tagColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Builds a priority badge
  static Widget buildPriorityBadge(String priority) {
    final color = getPriorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Builds a status badge
  static Widget buildStatusBadge(String status) {
    final color = getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Formats date string consistently
  static String formatDate(dynamic dateValue) {
    if (dateValue == null) return 'Unknown';
    
    DateTime dt;
    if (dateValue is DateTime) {
      dt = dateValue;
    } else {
      dt = DateTime.tryParse(dateValue.toString()) ?? DateTime.now();
    }
    
    return "${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  /// Builds a user avatar with initials
  static Widget buildUserAvatar({
    required String name,
    double size = 32,
    Color? backgroundColor,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF4A90E2),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty && name != 'Unknown'
              ? name.substring(0, 1).toUpperCase()
              : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Common dialog decoration
  static BoxDecoration getDialogDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2C3E50)
          : Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF9E9E9E),
          blurRadius: 20,
          offset: const Offset(0, 10),
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Common gradient for headers
  static LinearGradient getPrimaryGradient() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF4A90E2),
        Color(0xFF357ABD),
      ],
    );
  }
}