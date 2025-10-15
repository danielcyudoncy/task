// features/librarian/widgets/librarian_navbar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

class LibrarianNavbar extends StatelessWidget {
  final TabController tabController;
  final VoidCallback? onTabChanged;

  const LibrarianNavbar({
    super.key,
    required this.tabController,
    this.onTabChanged,
  });

  void _onTap(int index) {
    HapticFeedback.lightImpact();
    tabController.animateTo(index);
    onTabChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: tabController,
      builder: (context, child) {
        return ConvexAppBar(
          style: TabStyle.react,
          backgroundColor: colorScheme.surface,
          activeColor: colorScheme.onPrimary,
          color: colorScheme.onSurfaceVariant,
          elevation: 12,
          initialActiveIndex: tabController.index,
          onTap: _onTap,
          items: const [
            TabItem(icon: Icons.list_alt_rounded, title: 'All Tasks'),
            TabItem(
                icon: Icons.check_circle_outline_rounded, title: 'Completed'),
            TabItem(icon: Icons.schedule_rounded, title: 'Pending'),
          ],
        );
      },
    );
  }
}
