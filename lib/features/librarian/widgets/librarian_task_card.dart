// features/librarian/widgets/librarian_task_card.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:task/models/task_model.dart';
import 'package:task/features/librarian/screens/librarian_task_detail_screen.dart';
import 'package:task/features/librarian/widgets/task_actions.dart';
import 'package:task/theme/app_durations.dart';


class LibrarianTaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback? onTaskUpdated;

  const LibrarianTaskCard({
    super.key,
    required this.task,
    this.onTaskUpdated,
  });

  @override
  State<LibrarianTaskCard> createState() => _LibrarianTaskCardState();
}

class _LibrarianTaskCardState extends State<LibrarianTaskCard> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isLoading) return;
    
    try {
      setState(() => _isLoading = true);
      
      // Haptic feedback
      HapticFeedback.lightImpact();
      
      // Animate the tap
      await _animationController.forward();
      await _animationController.reverse();
      
      // Add a small delay for better UX
      await Future.delayed(AppDurations.fastAnimation);
      
      // Navigate to task detail
      final result = await Get.to<bool>(
        () => LibrarianTaskDetailScreen(task: widget.task),
        fullscreenDialog: true,
        duration: AppDurations.mediumAnimation,
        transition: Transition.downToUp,
      );
      
      // Callback if task was updated
      if (result == true && widget.onTaskUpdated != null) {
        widget.onTaskUpdated!();
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to open task: $e',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
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
    final dateFormat = DateFormat('MMM d, y');
    
    // Handle loading state
    if (_isLoading) {
      return _buildLoadingCard(theme);
    }
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: _buildTaskCard(theme, dateFormat),
    );
  }
  
  Widget _buildLoadingCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Loading task details...',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTaskCard(ThemeData theme, DateFormat dateFormat) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.dividerColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _handleTap,
          splashColor: theme.colorScheme.primary.withOpacity(0.1),
          highlightColor: theme.colorScheme.primary.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with title and status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.task.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(widget.task.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(widget.task.status).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.task.status,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _getStatusColor(widget.task.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Task details
              if (widget.task.description.isNotEmpty) ...[
                Text(
                  widget.task.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              
              // Metadata row
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (widget.task.category != null) ...[
                    _buildMetadataChip(
                      context,
                      icon: Icons.category_outlined,
                      label: widget.task.category!,
                    ),
                  ],
                  if (widget.task.dueDate != null) ...[
                    _buildMetadataChip(
                      context,
                      icon: Icons.event_available_outlined,
                      label: 'Due ${dateFormat.format(widget.task.dueDate!.toLocal())}',
                    ),
                  ],
                  if (widget.task.archivedAt != null) ...[
                    _buildMetadataChip(
                      context,
                      icon: Icons.archive_outlined,
                      label: 'Archived ${dateFormat.format(widget.task.archivedAt!.toLocal())}',
                      color: Colors.purple,
                    ),
                  ],
                ],
              ),
              
              // Tags
              if (widget.task.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.task.tags
                      .map((tag) => _buildTagChip(context, tag))
                      .toList(),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Footer with assigned users and actions
              Row(
                children: [
                  // Assigned users avatars
                  Expanded(
                    child: Row(
                      children: [
                        if (widget.task.assignedReporter != null)
                          _buildUserAvatar(
                            context,
                            name: widget.task.assignedReporter!,
                            tooltip: 'Reporter: ${widget.task.assignedReporter}',
                          ),
                        if (widget.task.assignedCameraman != null) ...[
                          const SizedBox(width: 4),
                          _buildUserAvatar(
                            context,
                            name: widget.task.assignedCameraman!,
                            tooltip: 'Cameraman: ${widget.task.assignedCameraman}',
                            isCameraman: true,
                          ),
                        ],
                        if (widget.task.assignedDriver != null) ...[
                          const SizedBox(width: 4),
                          _buildUserAvatar(
                            context,
                            name: widget.task.assignedDriver!,
                            tooltip: 'Driver: ${widget.task.assignedDriver}',
                            isDriver: true,
                          ),
                        ],
                        if (widget.task.assignedLibrarian != null) ...[
                          const SizedBox(width: 4),
                          _buildUserAvatar(
                            context,
                            name: widget.task.assignedLibrarian!,
                            tooltip: 'Librarian: ${widget.task.assignedLibrarian}',
                            isLibrarian: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Task actions
                  TaskActions(
                    task: widget.task,
                    onActionComplete: widget.onTaskUpdated,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),);
  }
  
  Widget _buildMetadataChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = color ?? colorScheme.onSurfaceVariant;
    
    return Tooltip(
      message: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (color ?? colorScheme.surfaceVariant).withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (color ?? colorScheme.outlineVariant).withOpacity(0.5),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: textColor,
            ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: textColor,
                  fontSize: 12,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTagChip(BuildContext context, String tag) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Tooltip(
      message: tag,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.3),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Text(
            tag,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              overflow: TextOverflow.ellipsis,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
  
  Widget _buildUserAvatar(
    BuildContext context, {
    required String name,
    String? tooltip,
    bool isCameraman = false,
    bool isDriver = false,
    bool isLibrarian = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final initials = _getInitials(name);
    
    // Determine avatar properties based on role
    late final IconData icon;
    late final Color backgroundColor;
    late final Color textColor;
    
    if (isCameraman) {
      icon = Icons.videocam_rounded;
      backgroundColor = Colors.blue.shade100;
      textColor = Colors.blue.shade800;
    } else if (isDriver) {
      icon = Icons.directions_car_rounded;
      backgroundColor = Colors.orange.shade100;
      textColor = Colors.orange.shade800;
    } else if (isLibrarian) {
      icon = Icons.library_books_rounded;
      backgroundColor = colorScheme.primaryContainer;
      textColor = colorScheme.onPrimaryContainer;
    } else {
      // Default for reporter/other
      icon = Icons.person_rounded;
      backgroundColor = colorScheme.surfaceVariant;
      textColor = colorScheme.onSurfaceVariant;
    }
    
    return Tooltip(
      message: tooltip ?? name,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.surface,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: isCameraman || isDriver || isLibrarian
              ? Icon(
                  icon, 
                  size: 16, 
                  color: textColor,
                  shadows: [
                    Shadow(
                      color: colorScheme.shadow.withOpacity(0.2),
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                )
              : Text(
                  initials,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
  
  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name.substring(0, name.length > 2 ? 2 : 1).toUpperCase();
    }
    return '??';
  }
  
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'archived':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
