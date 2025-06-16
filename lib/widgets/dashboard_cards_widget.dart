// widgets/dashboard_cards_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DashboardCardsWidget extends StatelessWidget {
  final int usersCount;
  final int tasksCount;
  final VoidCallback onManageUsersTap;
  final VoidCallback onTotalTasksTap;

  const DashboardCardsWidget({
    super.key,
    required this.usersCount,
    required this.tasksCount,
    required this.onManageUsersTap,
    required this.onTotalTasksTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Users Card
        Expanded(
          child: GestureDetector(
            onTap: onManageUsersTap,
            child: Card(
              color: colorScheme.primary,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 24.0, horizontal: 12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people, size: 36, color: colorScheme.onPrimary),
                    const SizedBox(height: 10),
                    Text(
                      '$usersCount',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Users',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Tasks Card
        Expanded(
          child: GestureDetector(
            onTap: onTotalTasksTap,
            child: Card(
              color: colorScheme.secondary,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 24.0, horizontal: 12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assignment,
                        size: 36, color: colorScheme.onSecondary),
                    const SizedBox(height: 10),
                    Text(
                      '$tasksCount',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tasks',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: colorScheme.onSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
