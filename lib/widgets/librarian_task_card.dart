// widgets/librarian_task_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/models/task_model.dart';
import 'package:task/views/librarian/task_detail_screen.dart';
import 'package:intl/intl.dart';

class LibrarianTaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onArchive;
  final VoidCallback? onEdit;
  final bool showArchiveButton;

  const LibrarianTaskCard({
    super.key,
    required this.task,
    this.onArchive,
    this.onEdit,
    this.showArchiveButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () {
          Get.to(() => TaskDetailScreen(task: task));
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and dates
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusChip(),
                  Text(
                    _formatDate(task.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Title
              Text(
                task.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Assigned to
              if (task.assignedReporter != null || task.assignedCameraman != null || task.assignedDriver != null)
                _buildAssignedToRow(),
              
              // Tags
              if (task.tags.isNotEmpty)
                _buildTagsRow(),
              
              // Actions
              if (showArchiveButton || onEdit != null)
                _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Chip(
      label: Text(
        task.status,
        style: TextStyle(
          color: _getStatusColor(),
          fontSize: 12,
        ),
      ),
      backgroundColor: _getStatusBackgroundColor(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildAssignedToRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.people_outline, size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _getAssignedToText(),
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.label_outline, size: 16),
            const SizedBox(width: 4),
            ...(task.tags).take(3).map((tag) => Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Chip(
                label: Text(tag, style: const TextStyle(fontSize: 10)),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            )),
            if (task.tags.length > 3)
              const Text('+ more', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onEdit != null)
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('EDIT', style: TextStyle(fontSize: 12)),
          ),
        if (showArchiveButton && task.status != 'Archived')
          TextButton(
            onPressed: onArchive,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('ARCHIVE', style: TextStyle(fontSize: 12)),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  String _getAssignedToText() {
    final assignedTo = <String>[];
    if (task.assignedReporter != null) {
      assignedTo.add('Reporter: ${task.assignedReporter}');
    }
    if (task.assignedCameraman != null) {
      assignedTo.add('Cameraman: ${task.assignedCameraman}');
    }
    if (task.assignedDriver != null) {
      assignedTo.add('Driver: ${task.assignedDriver}');
    }
    return assignedTo.join(' • ');
  }

  Color _getStatusColor() {
    final theme = Theme.of(Get.context!);
    switch (task.status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'archived':
        return theme.colorScheme.onSurface;
      default:
        return theme.colorScheme.primary;
    }
  }

  Color _getStatusBackgroundColor() {
    final theme = Theme.of(Get.context!);
    switch (task.status.toLowerCase()) {
      case 'completed':
        return Colors.green.withValues(alpha: 0.2);
      case 'archived':
        return theme.colorScheme.surfaceContainerHighest;
      default:
        return theme.colorScheme.primary.withValues(alpha: 0.1);
    }
  }
}
