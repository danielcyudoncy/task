// screens/librarian/task_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:task/controllers/task_controller.dart';

import 'package:task/models/task.dart';
import 'package:task/service/export_service.dart';
import 'package:task/service/pdf_export_service.dart';
import 'package:task/utils/constants/app_sizes.dart';
import 'package:task/utils/devices/app_devices.dart';
import 'package:task/widgets/task_action_utility.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskController _taskController = Get.find<TaskController>();
  final DateFormat _dateFormat = DateFormat('MMM d, y');

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.task.taskId.isEmpty) {
      setState(() {
        _errorMessage = 'Invalid task: Missing task ID';
      });
    }
  }

  // Helper method to safely get task ID
  String get _taskId => widget.task.taskId;

  Future<void> _handleTaskAction(Future<void> Function() action) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await action();
      if (mounted) {
        Get.snackbar(
          'Success',
          'Operation completed successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to complete operation: ${e.toString()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isTablet = AppDevices.isTablet(context);
    final screenWidth = AppDevices.getScreenWidth(context);

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.defaultPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: colorScheme.error,
                  size: 48,
                ),
                const SizedBox(height: AppSizes.md),
                Text(
                  _errorMessage!,
                  style:
                      textTheme.bodyLarge?.copyWith(color: colorScheme.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.lg),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          // Show loading indicator when performing actions
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (widget.task.status.toLowerCase() != 'archived')
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              onPressed: () => _handleTaskAction(() => _archiveTask(context)),
              tooltip: 'Archive Task',
            ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'export':
                  _showExportOptions(context);
                  break;
                case 'edit':
                  if (context.mounted) {
                    TaskActions.editTask(context, widget.task);
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.upload, size: 20),
                    SizedBox(width: 8),
                    Text('Export Task'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit Task'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(
          isTablet ? AppSizes.defaultPadding * 1.5 : AppSizes.defaultPadding,
        ),
        child: SizedBox(
          width: isTablet ? screenWidth * 0.8 : screenWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and dates
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.task.status.isNotEmpty)
                    Chip(
                      label: Text(
                        widget.task.status,
                        style: TextStyle(
                          color:
                              _getStatusColor(widget.task.status, colorScheme),
                        ),
                      ),
                      backgroundColor: _getStatusBackgroundColor(
                          widget.task.status, colorScheme),
                    ),
                  Text(
                    'Created: ${_dateFormat.format(widget.task.timestamp)}',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spaceBtwSections),

              // Task Title
              Text(
                widget.task.title,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 28 : null,
                ),
              ),
              const SizedBox(height: AppSizes.sm),

              // Assigned To
              if (widget.task.assignedReporterId != null ||
                  widget.task.assignedCameramanId != null ||
                  widget.task.assignedDriverId != null ||
                  widget.task.assignedLibrarianId != null) ...[
                _buildAssignedToSection(),
                const Divider(),
              ] else if (widget.task.description.isNotEmpty) ...[
                // This ensures the divider is added before the description if there are no assigned users
                const Divider(),
              ] else ...[
                // No assigned users and no description, so we don't need to add anything
              ],

              // Description
              if (widget.task.description.isNotEmpty) ...[
                Text(
                  'Description',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(widget.task.description),
                const SizedBox(height: AppSizes.spaceBtwSections),
              ],

              // Metadata Section
              _buildMetadataSection(),

              // Tags
              if (widget.task.tags.isNotEmpty) ...[
                const SizedBox(height: AppSizes.spaceBtwSections),
                _buildTagsSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Removed duplicate _buildAssignedToSection method
  // The version using _buildAssignedChip is kept as it provides better UI with icons

  Widget _buildMetadataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Text(
          'Metadata',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        _buildMetadataItem('Category', widget.task.category ?? 'Not specified'),
        _buildMetadataItem('Priority', widget.task.priority ?? 'Not specified'),
        if (widget.task.dueDate != null)
          _buildMetadataItem(
            'Due Date',
            DateFormat('MMM d, y').format(widget.task.dueDate!),
          ),
        _buildMetadataItem('Created By', _getCreatorName()),
        if (widget.task.status.toLowerCase() == 'completed' &&
            widget.task.lastModified != null)
          _buildMetadataItem(
            'Completed On',
            DateFormat('MMM d, y').format(widget.task.lastModified!),
          ),
        if (widget.task.archivedAt != null)
          _buildMetadataItem(
            'Archived On',
            DateFormat('MMM d, y').format(widget.task.archivedAt!),
          ),
      ],
    );
  }

  Widget _buildMetadataItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const Text(': '),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Text(
          'Tags',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children:
              widget.task.tags.map((tag) => Chip(label: Text(tag))).toList(),
        ),
      ],
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Export Task',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final exportService = Get.find<ExportService>();
                  await exportService.exportTasks(
                    tasks: [widget.task.toMap()],
                    format: ExportFormat.csv,
                    shareAfterExport: true,
                  );
                  Get.snackbar(
                    'Success',
                    'Task exported to CSV successfully',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                } catch (e) {
                  Get.snackbar(
                    'Error',
                    'Failed to export task: ${e.toString()}',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
              child: const Text('Export as CSV'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final pdfExportService = Get.find<PdfExportService>();
                  await pdfExportService.exportAndShareTask(widget.task);
                  Get.snackbar(
                    'Success',
                    'Task exported to PDF successfully',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                } catch (e) {
                  Get.snackbar(
                    'Error',
                    'Failed to export task: ${e.toString()}',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
              child: const Text('Export as PDF'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _archiveTask(BuildContext context) async {
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive Task'),
        content: const Text('Are you sure you want to archive this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _handleTaskAction(() async {
        await _taskController.updateTaskStatus(_taskId, 'Archived');
      });
      if (mounted) {
        navigator.pop();
      }
    }
  }

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'archived':
        return colorScheme.onSurface;
      default:
        return colorScheme.primary;
    }
  }

  Color _getStatusBackgroundColor(String status, ColorScheme colorScheme) {
    switch (status.toLowerCase()) {
      case 'completed':
        return colorScheme.primary.withValues(alpha: 0.1);
      case 'in progress':
        return colorScheme.secondary.withValues(alpha: 0.1);
      case 'pending':
        return colorScheme.tertiary.withValues(alpha: 0.1);
      case 'archived':
        return Colors.grey.withValues(alpha: 0.2);
      default:
        return Colors.grey.withValues(alpha: 0.1);
    }
  }

  Widget _buildAssignedToSection() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assigned To',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Wrap(
          spacing: AppSizes.sm,
          runSpacing: AppSizes.xs,
          children: [
            if (widget.task.assignedReporterId != null)
              _buildAssignedChip(
                widget.task.assignedReporter ??
                    'Reporter #${widget.task.assignedReporterId}',
                Icons.person_outline,
              ),
            if (widget.task.assignedCameramanId != null)
              _buildAssignedChip(
                widget.task.assignedCameraman ??
                    'Cameraman #${widget.task.assignedCameramanId}',
                Icons.videocam_outlined,
              ),
            if (widget.task.assignedDriverId != null)
              _buildAssignedChip(
                widget.task.assignedDriver ??
                    'Driver #${widget.task.assignedDriverId}',
                Icons.drive_eta_outlined,
              ),
            if (widget.task.assignedLibrarianId != null)
              _buildAssignedChip(
                widget.task.assignedLibrarian ??
                    'Librarian #${widget.task.assignedLibrarianId}',
                Icons.menu_book_outlined,
              ),
          ],
        ),
        const SizedBox(height: AppSizes.md),
      ],
    );
  }

  Widget _buildAssignedChip(String name, IconData icon) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSizes.xs),
          Text(
            name,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _getCreatorName() {
    try {
      // 1. Fallback to createdBy field first (synchronous)
      if (widget.task.createdBy.isNotEmpty) {
        return widget.task.createdBy;
      }

      // 2. Final fallback
      return 'Unknown';
    } catch (e) {
      debugPrint('Error getting creator name: $e');
      return widget.task.createdBy;
    }
  }
}
