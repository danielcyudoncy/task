// widgets/assign_task_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/widgets/dashboard_utils.dart';
import '../../controllers/admin_controller.dart';

class AssignTaskDialog extends StatefulWidget {
  final Map<String, dynamic>? user;
  final AdminController adminController;

  const AssignTaskDialog({
    super.key,
    this.user,
    required this.adminController,
  });

  @override
  State<AssignTaskDialog> createState() => _AssignTaskDialogState();
}

class _AssignTaskDialogState extends State<AssignTaskDialog> {
  String? selectedTaskTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final assignableTasks = widget.adminController.taskSnapshotDocs.where((task) {
      final completed = (task['status'] ?? '').toString().toLowerCase() == 'completed';
      
      // Check if task has been approved by admin
      final isApproved = (task['approved'] ?? false) == true || (task['isApproved'] ?? false) == true;
      
      // Check if both reporter and cameraman are assigned
      final hasReporter = task['assignedReporterId'] != null && task['assignedReporterId'].toString().isNotEmpty;
      final hasCameraman = task['assignedCameramanId'] != null && task['assignedCameramanId'].toString().isNotEmpty;
      final fullyAssigned = hasReporter && hasCameraman;
      
      // Task is available if it's approved, not completed and not fully assigned (missing reporter or cameraman)
      return isApproved && !completed && !fullyAssigned;
    }).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: BoxConstraints(
          maxWidth: 380.w,
          minWidth: 300.w,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
                ? [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                    const Color(0xFF0F3460),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFF8FAFF),
                    const Color(0xFFE3F2FD),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: assignableTasks.isEmpty
            ? _buildEmptyState(theme, isDark)
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with gradient
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryColor,
                            primaryColor.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.assignment_turned_in,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Assign Task",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              if (widget.user != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  "to ${widget.user?['fullName'] ?? widget.user?['fullname'] ?? ''}",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Task Selection Section
                        Text(
                          "Select Task",
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Modern Dropdown
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selectedTaskTitle != null 
                                  ? primaryColor.withValues(alpha: 0.3)
                                  : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2)),
                              width: selectedTaskTitle != null ? 2 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: selectedTaskTitle != null 
                                    ? primaryColor.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.05),
                                blurRadius: selectedTaskTitle != null ? 15 : 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: selectedTaskTitle,
                              menuMaxHeight: 200,
                              dropdownColor: isDark ? const Color(0xFF2A2A3E) : Colors.white,
                              hint: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.task_alt,
                                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Select task",
                                        style: TextStyle(
                                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: primaryColor,
                                  size: 20,
                                ),
                              ),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              items: assignableTasks.map((task) {
                                final title = task['title'] ?? '';
                                final creatorName = (task['creatorName'] ?? task['creator'] ?? '').toString();
                                final description = task['description'] ?? '';
                                final dueDate = task['dueDate'];
                                
                                return DropdownMenuItem<String>(
                                  value: title,
                                  child: _buildTaskItem(
                                    context,
                                    task,
                                    title,
                                    creatorName,
                                    description,
                                    dueDate,
                                    isDark,
                                    primaryColor,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  setState(() => selectedTaskTitle = val);
                                });
                              },
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: _buildButton(
                                context,
                                "Cancel",
                                Icons.close,
                                isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                                isDark ? Colors.white : Colors.black87,
                                () => Get.back(),
                                isOutlined: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildButton(
                                context,
                                "Assign",
                                Icons.check_circle,
                                primaryColor,
                                Colors.white,
                                () => _handleAssignTask(assignableTasks),
                              ),
                            ),
                          ],
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

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark 
                    ? [Colors.grey.shade800, Colors.grey.shade700]
                    : [Colors.grey.shade100, Colors.grey.shade200],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.task_alt_outlined,
              size: 48,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No Tasks Available",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "All tasks are either assigned or completed",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white70 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildButton(
            context,
            "Close",
            Icons.close,
            Theme.of(context).colorScheme.primary,
            Colors.white,
            () => Get.back(),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    Map<String, dynamic> task,
    String title,
    String creatorName,
    String description,
    dynamic dueDate,
    bool isDark,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A3E) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Creator Avatar
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withAlpha((0.7 * 255).round())],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                getCreatorInitials(task),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          
          // Task Title
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          
          // Status Icon
          Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: getPriorityColor(task).withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Icon(
              getStatusIcon(task),
              color: getPriorityColor(task),
              size: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    String text,
    IconData icon,
    Color backgroundColor,
    Color textColor,
    VoidCallback onPressed, {
    bool isOutlined = false,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: isOutlined ? null : LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [backgroundColor, backgroundColor.withAlpha((0.8 * 255).round())],
        ),
        color: isOutlined ? Colors.transparent : backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: isOutlined ? Border.all(color: backgroundColor, width: 2) : null,
        boxShadow: isOutlined ? null : [
          BoxShadow(
            color: backgroundColor.withAlpha((0.3 * 255).round()),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
              child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
          onTap: () {
            Get.find<SettingsController>().triggerFeedback();
            onPressed();
          },
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: textColor, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleAssignTask(List<Map<String, dynamic>> assignableTasks) async {
    if (selectedTaskTitle == null) {
      Get.snackbar(
        "Error",
        "Please select a task",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 12,
      );
      return;
    }
    
    if (widget.user == null) {
      Get.back();
      return;
    }
    
    final userId = widget.user?['uid'] ?? widget.user?['id'];
    if (userId == null) {
      Get.snackbar(
        "Error", 
        "User ID is missing",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 12,
      );
      return;
    }
    
    final selectedTaskDoc = assignableTasks.firstWhere(
      (d) => d['title'] == selectedTaskTitle,
      orElse: () => <String, dynamic>{},
    );

    final String taskId = selectedTaskDoc['id'] ?? selectedTaskDoc['taskId'];
    final String taskDescription = selectedTaskDoc['description'] ?? "";
    final DateTime dueDate = (selectedTaskDoc['dueDate'] is Timestamp)
        ? (selectedTaskDoc['dueDate'] as Timestamp).toDate()
        : DateTime.tryParse(selectedTaskDoc['dueDate']?.toString() ?? "") ?? DateTime.now();

    try {
      await widget.adminController.assignTaskToUser(
        userId: userId,
        assignedName: widget.user?['fullName'] ?? widget.user?['fullname'] ?? '',
        taskTitle: selectedTaskTitle!,
        taskDescription: taskDescription,
        dueDate: dueDate,
        taskId: taskId,
      );
      
      Get.back();
      Get.snackbar(
        "Success",
        "Task assigned to ${widget.user?['fullName'] ?? widget.user?['fullname'] ?? ''}",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 12,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to assign task: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        borderRadius: 12,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    }
  }
}
