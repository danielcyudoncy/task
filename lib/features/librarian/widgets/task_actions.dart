// features/librarian/widgets/task_actions.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:task/models/task_model.dart';
import 'package:task/service/archive_service.dart';
import 'package:task/service/export_service.dart';
import 'package:task/theme/app_durations.dart';


class TaskActions extends StatefulWidget {
  final Task task;
  final VoidCallback? onActionComplete;
  
  const TaskActions({
    super.key,
    required this.task,
    this.onActionComplete,
  });

  @override
  State<TaskActions> createState() => _TaskActionsState();
}

class _TaskActionsState extends State<TaskActions> with SingleTickerProviderStateMixin {
  bool _isArchiving = false;
  bool _isExporting = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppDurations.fastAnimation,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Archive/Unarchive button
          if (widget.task.status.toLowerCase() != 'archived')
            _buildArchiveButton()
          else
            _buildUnarchiveButton(),
          
          // Export button
          _buildExportButton(theme, colorScheme),
        ],
      ),
    );
  }
  
  Widget _buildArchiveButton() {
    return IconButton(
      icon: _isArchiving
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          : Icon(Icons.archive_outlined, color: Theme.of(context).colorScheme.onPrimary),
      tooltip: 'Archive Task',
      onPressed: _isArchiving
          ? null
          : () => _showArchiveDialog(
                context,
                widget.task,
                Get.find<ArchiveService>(),
              ),
    );
  }
  
  Widget _buildUnarchiveButton() {
    return IconButton(
      icon: _isArchiving
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          : Icon(Icons.unarchive_outlined, color: Theme.of(context).colorScheme.onPrimary),
      tooltip: 'Unarchive Task',
      onPressed: _isArchiving
          ? null
          : () => _unarchiveTask(widget.task, Get.find<ArchiveService>()),
    );
  }
  
  Widget _buildExportButton(ThemeData theme, ColorScheme colorScheme) {
    return PopupMenuButton<String>(
      icon: _isExporting
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onPrimary,
              ),
            )
          : Icon(Icons.ios_share, color: Theme.of(context).colorScheme.onPrimary),
      onCanceled: () {
        if (_isExporting) {
          // Prevent menu from closing when exporting
          _animationController.reverse();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'pdf',
          enabled: !_isExporting,
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf, color: Colors.red),
              const SizedBox(width: 12),
              Text('Export as PDF'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'csv',
          enabled: !_isExporting,
          child: Row(
            children: [
              const Icon(Icons.table_chart, color: Colors.green),
              const SizedBox(width: 12),
              Text('Export as CSV'),
            ],
          ),
        ),
      ],
      onSelected: (value) => _handleExport(value),
    );
  }
  
  Future<void> _handleExport(String format) async {
    if (_isExporting) return;
    
    try {
      setState(() => _isExporting = true);
      
      // Haptic feedback
      HapticFeedback.lightImpact();
      
      // Animate the tap
      await _animationController.forward();
      
      final exportService = Get.find<ExportService>();
      
      if (format == 'pdf') {
        final file = await exportService.exportToPdf([widget.task]);
        await exportService.shareFile(
          file,
          subject: 'Task Export - ${widget.task.title}',
          text: 'Here is the exported task in PDF format.',
        );
      } else if (format == 'csv') {
        final file = await exportService.exportToCsv([widget.task]);
        await exportService.shareFile(
          file,
          subject: 'Task Export - ${widget.task.title}',
          text: 'Here is the exported task in CSV format.',
        );
      }
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task exported as ${format.toUpperCase()}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting task: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
        _animationController.reverse();
      }
    }
  }

  Future<void> _showArchiveDialog(
    BuildContext context, 
    Task task, 
    ArchiveService archiveService,
  ) async {
    final reasonController = TextEditingController();
    final locationController = TextEditingController();
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Archive Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Please provide a reason for archiving this task:'),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason for archiving',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('Location (optional):'),
                const SizedBox(height: 8),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Physical/Digital location',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Shelf A-12, Cloud Storage, etc.',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please provide a reason for archiving')),
                    );
                  }
                  return;
                }
                
                Navigator.of(context).pop();
                
                try {
                  await archiveService.archiveTask(
                    taskId: task.taskId,
                    reason: reasonController.text.trim(),
                    location: locationController.text.trim().isNotEmpty 
                        ? locationController.text.trim() 
                        : null,
                  );
                  
                  if (widget.onActionComplete != null) {
                    widget.onActionComplete!();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error archiving task: $e')),
                    );
                  }
                }
              },
              child: const Text('Archive'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _unarchiveTask(Task task, ArchiveService archiveService) async {
    if (_isArchiving) return;
    
    try {
      setState(() => _isArchiving = true);
      
      // Haptic feedback
      HapticFeedback.lightImpact();
      
      await archiveService.unarchiveTask(task.taskId);
      
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task unarchived successfully'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      if (widget.onActionComplete != null) {
        widget.onActionComplete!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unarchive task: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isArchiving = false);
      }
    }
  }
}
