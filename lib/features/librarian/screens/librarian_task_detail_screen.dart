// features/librarian/screens/librarian_task_detail_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:task/models/task_model.dart';
import 'package:task/features/librarian/widgets/task_actions.dart';
import 'package:task/features/librarian/widgets/task_attachments_widget.dart';
import 'package:task/theme/app_durations.dart';


class LibrarianTaskDetailScreen extends StatefulWidget {
  final Task task;

  const LibrarianTaskDetailScreen({
    super.key,
    required this.task,
  });

  @override
  State<LibrarianTaskDetailScreen> createState() =>
      _LibrarianTaskDetailScreenState();
}

class _LibrarianTaskDetailScreenState extends State<LibrarianTaskDetailScreen>
    with SingleTickerProviderStateMixin {
  late Task _task;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _animationController = AnimationController(
      vsync: this,
      duration: AppDurations.mediumAnimation,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshTask() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final TaskController taskController = Get.find<TaskController>();
      final refreshedTask = await taskController.getTaskById(_task.taskId);

      setState(() {
        _task = refreshedTask!;
      });

      HapticFeedback.lightImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task refreshed'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM d, y HH:mm');
    
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header with drag handle and actions
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Header row with title and actions
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Task Details',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      // Refresh button
                      IconButton(
                        icon: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.primary,
                                ),
                              )
                            : const Icon(Icons.refresh),
                        onPressed: _isLoading ? null : _refreshTask,
                        tooltip: 'Refresh',
                      ),
                      // Task actions
                      TaskActions(
                        task: _task,
                        onActionComplete: () {
                          // Refresh the task after an action is completed
                          _refreshTask();
                          // Notify parent if needed
                          if (mounted) {
                            Get.back(result: true);
                          }
                        },
                      ),
                      // Close button
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Get.back(),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshTask,
                color: colorScheme.primary,
                backgroundColor: colorScheme.surface,
                strokeWidth: 2.5,
                edgeOffset: 0,
                triggerMode: RefreshIndicatorTriggerMode.anywhere,
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
            // Task title and status with animation
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with copy to clipboard
                  GestureDetector(
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: _task.title));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Title copied to clipboard'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _task.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.content_copy,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Status and approval chips
                  Row(
                    children: [
                      // Status chip with animation
                      AnimatedContainer(
                        duration: AppDurations.fastAnimation,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_task.status),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _getStatusColor(_task.status).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _task.status.toUpperCase(),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Approval status chip
                      if (_task.approvalStatus != null && _task.approvalStatus != 'pending')
                        AnimatedContainer(
                          duration: AppDurations.fastAnimation,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _task.isApproved 
                                ? Colors.green 
                                : _task.isRejected 
                                    ? Colors.red 
                                    : Colors.grey,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (_task.isApproved 
                                    ? Colors.green 
                                    : _task.isRejected 
                                        ? Colors.red 
                                        : Colors.grey).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _task.isApproved 
                                    ? Icons.check_circle 
                                    : Icons.cancel,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _task.approvalStatus!.toUpperCase(),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Task details section
            _buildSection(
              context,
              title: 'Task Details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onLongPress: () {
                      if (_task.description.isNotEmpty) {
                        Clipboard.setData(ClipboardData(text: _task.description));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Description copied to clipboard'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    child: _buildDetailRow(
                      context,
                      icon: Icons.description_outlined,
                      label: 'Description',
                      value: _task.description.isNotEmpty 
                          ? _task.description 
                          : 'No description provided',
                    ),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    icon: Icons.category_outlined,
                    label: 'Category',
                    value: _task.category ?? 'Uncategorized',
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    icon: Icons.label_outline,
                    label: 'Tags',
                    value: _task.tags.isNotEmpty 
                        ? _task.tags.join(', ') 
                        : 'No tags',
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(
                    context,
                    icon: Icons.priority_high,
                    label: 'Priority',
                    value: _task.priority ?? 'Not specified',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Dates section
            _buildSection(
              context,
              title: 'Timeline',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    context,
                    icon: Icons.calendar_today_outlined,
                    label: 'Created',
                    value: dateFormat.format(_task.timestamp.toLocal()),
                  ),
                  if (_task.dueDate != null) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      context,
                      icon: Icons.event_available_outlined,
                      label: 'Due Date',
                      value: dateFormat.format(_task.dueDate!.toLocal()),
                    ),
                  ],
                  if (_task.status.toLowerCase() == 'completed' && _task.lastModified != null) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      context,
                      icon: Icons.check_circle_outline,
                      label: 'Completed',
                      value: dateFormat.format(_task.lastModified!.toLocal()),
                    ),
                  ],
                  if (_task.archivedAt != null) ...[
                    const Divider(height: 24),
                    _buildDetailRow(
                      context,
                      icon: Icons.archive_outlined,
                      label: 'Archived',
                      value: '${dateFormat.format(_task.archivedAt!.toLocal())}'
                          '${_task.archivedBy != null ? ' by ${_task.archivedBy}' : ''}',
                    ),
                    if (_task.archiveReason != null) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        context,
                        icon: Icons.info_outline,
                        label: 'Archive Reason',
                        value: _task.archiveReason!,
                      ),
                    ],
                    if (_task.archiveLocation != null) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        context,
                        icon: Icons.location_on_outlined,
                        label: 'Archive Location',
                        value: _task.archiveLocation!,
                      ),
                    ],
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Approval information section
            if (_task.approvalStatus != null && _task.approvalStatus != 'pending')
              _buildSection(
                context,
                title: 'Approval Status',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      context,
                      icon: _task.isApproved ? Icons.check_circle_outline : Icons.cancel_outlined,
                      label: _task.isApproved ? 'Approved' : 'Rejected',
                      value: _task.approvalTimestamp != null 
                          ? dateFormat.format(_task.approvalTimestamp!.toLocal())
                          : 'Unknown date',
                    ),
                    if (_task.approvedBy != null) ...[
                      const Divider(height: 24),
                      _buildDetailRow(
                        context,
                        icon: Icons.person_outline,
                        label: _task.isApproved ? 'Approved By' : 'Rejected By',
                        value: _getApproverName(_task.approvedBy!),
                      ),
                    ],
                    if (_task.approvalReason != null && _task.approvalReason!.isNotEmpty) ...[
                      const Divider(height: 24),
                      _buildDetailRow(
                        context,
                        icon: Icons.comment_outlined,
                        label: _task.isApproved ? 'Approval Reason' : 'Rejection Reason',
                        value: _task.approvalReason!,
                      ),
                    ],
                  ],
                ),
              ),
              
            if (_task.approvalStatus != null && _task.approvalStatus != 'pending')
              const SizedBox(height: 24),
            
            // Assigned users section
            _buildSection(
              context,
              title: 'Assigned To',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_task.assignedReporter != null)
                    _buildUserChip(
                      context,
                      label: 'Reporter',
                      name: _task.assignedReporter!,
                      icon: Icons.person_outline,
                    ),
                  if (_task.assignedCameraman != null) ...[
                    const SizedBox(height: 8),
                    _buildUserChip(
                      context,
                      label: 'Cameraman',
                      name: _task.assignedCameraman!,
                      icon: Icons.videocam_outlined,
                    ),
                  ],
                  if (_task.assignedDriver != null) ...[
                    const SizedBox(height: 8),
                    _buildUserChip(
                      context,
                      label: 'Driver',
                      name: _task.assignedDriver!,
                      icon: Icons.directions_car_outlined,
                    ),
                  ],
                  if (_task.assignedLibrarian != null) ...[
                    const SizedBox(height: 8),
                    _buildUserChip(
                      context,
                      label: 'Librarian',
                      name: _task.assignedLibrarian!,
                      icon: Icons.library_books_outlined,
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Attachments section
            TaskAttachmentsWidget(
              task: _task,
              onTaskUpdated: (updatedTask) {
                setState(() {
                  _task = updatedTask;
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            // Comments section
            if (_task.comments.isNotEmpty)
              _buildSection(
                context,
                title: 'Comments',
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _task.comments.length,
                  separatorBuilder: (_, __) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    return Text(
                      _task.comments[index],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    );
                  },
                ),
              ),
            
            const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: isDark ? null : [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }
  
  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildUserChip(
    BuildContext context, {
    required String label,
    required String name,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurface),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            name,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
  
  String _getApproverName(String userId) {
    final TaskController taskController = Get.find<TaskController>();
    return taskController.userNameCache[userId] ?? 'Unknown User';
  }

  Color _getStatusColor(String status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status.toLowerCase()) {
      case 'completed':
        return colorScheme.secondary;
      case 'in progress':
        return colorScheme.primary;
      case 'pending':
        return colorScheme.tertiary;
      case 'archived':
        return colorScheme.outline;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }
}
