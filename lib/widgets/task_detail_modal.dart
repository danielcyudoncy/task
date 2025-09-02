// widgets/task_detail_modal.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:task/models/task_model.dart';
import 'package:task/controllers/settings_controller.dart';
import 'status_chip.dart';

class TaskDetailModal extends StatelessWidget {
  final Task task;
  final bool isDark;

  const TaskDetailModal({
    super.key,
    required this.task,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Theme-aware colors
    final Color bgColor = colorScheme.surface;
    final Color mainText = colorScheme.onSurface;
    final Color subText = colorScheme.onSurfaceVariant;
    final Color accent = colorScheme.primary;

    return Dialog(
      
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 500.w,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(32),
          
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 30,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.task_alt,
                    color: colorScheme.primary,
                    size: 24.sp,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Task Details',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.sp,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Get.find<SettingsController>().triggerFeedback();
                      Navigator.of(context).pop();
                    },
                    icon: Icon(
                      Icons.close,
                      color:Colors.white,
                      size: 24.sp,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Status
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start, // Align title to left
                            children: [
                              Text(
                                task.title,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: mainText,
                                  fontSize: 22.sp,
                                ),
                              ),
                              const SizedBox(
                                  height: 8), // Add some vertical spacing
                              Align(
                                alignment: Alignment
                                    .centerRight, // Align status to right
                                child: StatusChip(
                                  status: task.status,
                                  textScale: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Completion Comments
                    _buildCompletionComments(context),
                    const SizedBox(height: 16),

                    // Description
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        task.description,
                        style: textTheme.bodyLarge?.copyWith(
                          color: mainText,
                          fontSize: 14.sp,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Task Details Grid
                    _buildDetailSection(
                      context,
                      'Task Information',
                      [
                        _buildDetailRow(
                            context,
                            'Created by',
                            task.createdBy.isNotEmpty
                                ? task.createdBy
                                : 'Not assigned',
                            Icons.person_outline),
                        if (task.category != null && task.category!.isNotEmpty)
                          _buildDetailRow(context, 'Category', task.category!,
                              Icons.category_outlined),
                        if (task.priority != null && task.priority!.isNotEmpty)
                          _buildDetailRow(context, 'Priority', task.priority!,
                              Icons.flag_outlined,
                              valueColor: _getPriorityColor(task.priority!)),
                        if (task.dueDate != null)
                          _buildDetailRow(
                              context,
                              'Due Date',
                              DateFormat('MMM dd, yyyy HH:mm')
                                  .format(task.dueDate!),
                              Icons.schedule_outlined),
                        _buildDetailRow(
                            context,
                            'Created',
                            DateFormat('MMM dd, yyyy HH:mm')
                                .format(task.timestamp),
                            Icons.access_time_outlined),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Assignment Details
                    _buildDetailSection(
                      context,
                      'Assignment Details',
                      [
                        _buildDetailRow(
                            context,
                            'Reporter',
                            task.assignedReporter ?? 'Not assigned',
                            Icons.person_outline),
                        _buildDetailRow(
                            context,
                            'Cameraman',
                            task.assignedCameraman ?? 'Not assigned',
                            Icons.videocam_outlined),
                        _buildDetailRow(
                            context,
                            'Driver',
                            task.assignedDriver ?? 'Not assigned',
                            Icons.directions_car_outlined),
                        
                      ],
                    ),

                    // Tags Section
                    const SizedBox(height: 16),
                    _buildDetailSection(
                      context,
                      'Tags',
                      [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12.w),
                          child: task.tags.isNotEmpty
                              ? Wrap(
                                  spacing: 8.w,
                                  runSpacing: 8.h,
                                  children: task.tags
                                      .map((tag) => Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12.w,
                                                vertical: 6.h),
                                            decoration: BoxDecoration(
                                              color: colorScheme.primaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                            child: Text(
                                              tag,
                                              style:
                                                  textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onPrimaryContainer,
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                )
                              : Text(
                                  'No tags assigned',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: subText,
                                    fontSize: 14.sp,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                        ),
                      ],
                    ),

                    // Comments (if available and task is not approved)
                    if (task.comments.isNotEmpty && task.approvalStatus?.toLowerCase() != 'approved') ...[
                      const SizedBox(height: 16),
                      _buildDetailSection(
                        context,
                        'Pending Comments (${task.comments.length})',
                        task.comments
                            .map((comment) => Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(12.w),
                                  margin: EdgeInsets.only(bottom: 8.h),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: colorScheme.errorContainer.withOpacity(0.5),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    comment,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: mainText,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(
      BuildContext context, String title, List<Widget> children) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              fontSize: 14.sp,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCompletionComments(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    // Check if there are any completion info entries
    if (task.reportCompletionInfo.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Get the first completion info entry
    final completionInfo = task.reportCompletionInfo.values.first;
    
    return _buildDetailSection(
      context,
      'Completion Details',
      [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (completionInfo.comments != null && 
                  completionInfo.comments!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    completionInfo.comments!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              if (completionInfo.videoEditorName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Video Editor: ${completionInfo.videoEditorName}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              if (completionInfo.airTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Aired: ${completionInfo.airTime!.toLocal()}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
      BuildContext context, String label, String value, IconData icon,
      {Color? valueColor}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18.sp,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Text(
              '$label: ',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
                fontSize: 14.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: valueColor ?? colorScheme.onSurface,
                fontSize: 12.sp,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
