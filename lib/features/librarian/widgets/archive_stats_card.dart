// features/librarian/widgets/archive_stats_card.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class ArchiveStatsCard extends StatelessWidget {
  final int totalArchived;
  final int archivedThisMonth;
  final VoidCallback onToggleArchive;
  final bool showArchived;
  final bool isLoading;
  final String? error;
  final VoidCallback? onTotalArchivedTap;

  const ArchiveStatsCard({
    super.key,
    required this.totalArchived,
    required this.archivedThisMonth,
    required this.onToggleArchive,
    required this.showArchived,
    this.isLoading = false,
    this.error,
    this.onTotalArchivedTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceVariant.withValues(alpha: 0.3)
            : colorScheme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: isDark
            ? Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: isDark ? 0.2 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Archive Stats',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? colorScheme.onSurface : colorScheme.primary,
                ),
              ),
              if (!isLoading && error == null)
                _buildToggleButton(theme, colorScheme),
            ],
          ),

          const SizedBox(height: 12),

          // Content
          if (isLoading)
            _buildLoadingState(theme, colorScheme)
          else if (error != null)
            _buildErrorState(theme, error!)
          else
            _buildStatsContent(context, theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildToggleButton(ThemeData theme, ColorScheme colorScheme) {
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Text(
          showArchived ? 'Hide Archived' : 'Show Archived',
          style: theme.textTheme.labelSmall?.copyWith(
            color: isDark ? colorScheme.onSurface : colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: Icon(
            showArchived
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 18,
            color: isDark ? colorScheme.onSurface : colorScheme.primary,
          ),
          onPressed: onToggleArchive,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          iconSize: 18,
          tooltip: showArchived ? 'Hide archived tasks' : 'Show archived tasks',
        ),
      ],
    );
  }

  Widget _buildLoadingState(ThemeData theme, ColorScheme colorScheme) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Failed to load archive stats: $error',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () => onToggleArchive(),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        _buildStatItem(
          context: context,
          label: 'Total Archived',
          value: showArchived ? totalArchived : null,
          icon: Icons.archive_outlined,
          color: colorScheme.primary,
          onTap: onTotalArchivedTap,
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          context: context,
          label: 'This Month',
          value: archivedThisMonth,
          icon: Icons.calendar_today_outlined,
          color: colorScheme.secondary,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required BuildContext context,
    required String label,
    required int? value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 100, // Fixed height to ensure both cards are the same size
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              if (!isDark) ...[
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon and label row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: isDark ? colorScheme.onSurface : color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Value
              Text(
                value?.toString() ?? '---',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: value != null
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              // Subtle trend indicator (example - could be dynamic based on data)
              if (label == 'This Month' && value != null && value > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_upward_rounded,
                        size: 12,
                        color: isDark ? Colors.green.shade300 : Colors.green,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${(value / 10).ceil() * 10}% from last month',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDark
                              ? colorScheme.onSurfaceVariant
                              : colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
