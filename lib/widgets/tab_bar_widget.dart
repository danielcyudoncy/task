// widgets/tab_bar_widget.dart
import 'package:flutter/material.dart';

class TabBarWidget extends StatelessWidget {
  final TabController tabController;
  final List<String> tabTitles;

  const TabBarWidget({
    super.key,
    required this.tabController,
    required this.tabTitles,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return TabBar(
      controller: tabController,
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isDark ? Colors.white : colorScheme.primary,
      ),
      labelColor: isDark ? Colors.white : colorScheme.primary,
      unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
      tabs: tabTitles
          .map((title) => Tab(
                text: title,
              ))
          .toList(),
    );
  }
}
