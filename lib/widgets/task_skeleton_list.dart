// widgets/task_skeleton_list.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class TaskSkeletonList extends StatelessWidget {
  final bool isLargeScreen;
  final double textScale;
  const TaskSkeletonList({required this.isLargeScreen, required this.textScale, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    // Theme-aware skeleton colors
    final baseColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[600]! : Colors.grey[100]!;
    final skeletonColor = isDark ? Colors.grey[800]! : Colors.white;
    final dividerColor = theme.dividerColor;
    
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (_, __) => Divider(
        color: dividerColor,
        thickness: 1,
        indent: 16,
        endIndent: 16,
      ),
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 16 : 8.0, vertical: 4.0),
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: isLargeScreen ? 120 : 90,
              decoration: BoxDecoration(
                color: skeletonColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}