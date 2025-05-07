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
    return TabBar(
      controller: tabController,
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF0B189B),
      ),
      labelColor: Colors.white,
      unselectedLabelColor: Colors.black,
      tabs: tabTitles
          .map((title) => Tab(
                text: title,
              ))
          .toList(),
    );
  }
}
