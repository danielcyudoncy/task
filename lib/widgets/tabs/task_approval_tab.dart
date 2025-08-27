// widgets/tabs/task_approval_tab.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/task_model.dart';
import '../ui_helpers.dart';

class TaskApprovalTab extends StatelessWidget {
  final Map<String, Map<String, String>> userCache;
  final Future<Map<String, String>> Function(String, VoidCallback) getUserNameAndRole;

  const TaskApprovalTab({
    super.key,
    required this.userCache,
    required this.getUserNameAndRole,
  });

  @override
  Widget build(BuildContext context) {
    final TaskController taskController = Get.find<TaskController>();
    final AuthController authController = Get.find<AuthController>();

    return Obx(() {
      if (taskController.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      final pendingTasks = taskController.pendingApprovalTasks;
      
      if (pendingTasks.isEmpty) {
        return _buildEmptyState(context);
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pendingTasks.length,
        itemBuilder: (context, index) {
          final task = pendingTasks[index];
          return _buildTaskCard(context, task, authController);
        },
      );
    });
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.approval_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks pending approval',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All tasks have been reviewed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task, AuthController authController) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Theme.of(context).primaryColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTaskApprovalDialog(context, task),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withValues(alpha: 0.9),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'Pending Approval',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: FutureBuilder<Map<String, String>>(
                        future: getUserNameAndRole(task.createdById, () {}),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final creatorName = snapshot.data!['name'] ?? 'Unknown';
                            return Text(
                              'Created by $creatorName',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                              ),
                            );
                          }
                          return Text(
                            'Loading creator...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.6),
                            ),
                          );
                        },
                      ),
                    ),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      UIHelpers.formatDate(task.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                if (task.category != null || task.priority != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (task.category != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            task.category!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (task.priority != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(task.priority!).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _getPriorityColor(task.priority!).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            task.priority!,
                            style: TextStyle(
                              color: _getPriorityColor(task.priority!),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
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

  void _showTaskApprovalDialog(BuildContext context, Task task) async {
    final TaskController taskController = Get.find<TaskController>();
    final TextEditingController commentController = TextEditingController();
    
    // Get creator info
    final creatorInfo = await getUserNameAndRole(task.createdById, () {});
    final creatorName = creatorInfo['name'] ?? 'Unknown';
    final creatorRole = creatorInfo['role'] ?? 'Unknown';
    
    // Format creator display text
    String creatorDisplay;
    if (creatorName != 'Unknown') {
      // If we have a real name, only show role if it's not 'Unknown'
      if (creatorRole != 'Unknown') {
        creatorDisplay = '$creatorName ($creatorRole)';
      } else {
        creatorDisplay = creatorName;
      }
    } else {
      // If no name available, show 'Unknown'
      creatorDisplay = 'Unknown';
    }
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Theme.of(dialogContext).colorScheme.surface,
          child: Container(
            width: MediaQuery.of(dialogContext).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: Theme.of(dialogContext).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(dialogContext).colorScheme.primary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.approval_outlined,
                            color: Theme.of(dialogContext).colorScheme.onPrimary,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Task Approval',
                              style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                                color: Theme.of(dialogContext).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: Icon(
                              Icons.close,
                              color: Theme.of(dialogContext).colorScheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        task.title,
                        style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                          color: Theme.of(dialogContext).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Task Details Section
                        _buildDetailSection(
                          dialogContext,
                          'Task Details',
                          Icons.assignment,
                          [
                            _buildDetailRow(dialogContext, 'Description', task.description),
                            _buildDetailRow(dialogContext, 'Created by', creatorDisplay),
                            _buildDetailRow(dialogContext, 'Status', task.status),
                            if (task.category != null) _buildDetailRow(dialogContext, 'Category', task.category!),
                            if (task.priority != null) _buildDetailRow(dialogContext, 'Priority', task.priority!),
                            if (task.dueDate != null) _buildDetailRow(dialogContext, 'Due Date', UIHelpers.formatDate(task.dueDate!)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Comments Section
                        _buildDetailSection(
                          dialogContext,
                          'Comments',
                          Icons.comment,
                          [
                            const SizedBox(height: 8),
                            TextField(
                              controller: commentController,
                              maxLines: 4,
                              style: TextStyle(
                                color: Theme.of(dialogContext).colorScheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Add your comments here (optional)...',
                                hintStyle: TextStyle(
                                  color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Theme.of(dialogContext).colorScheme.outline,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Theme.of(dialogContext).colorScheme.outline,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Theme.of(dialogContext).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Theme.of(dialogContext).colorScheme.surface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(dialogContext).colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final navigator = Navigator.of(dialogContext);
                            final comment = commentController.text.trim();
                            await taskController.rejectTask(
                              task.taskId,
                              reason: comment.isEmpty ? 'Rejected by admin' : comment,
                            );
                            // Refresh tasks to update UI
                            await taskController.refreshTasks();
                            if (dialogContext.mounted) navigator.pop();
                          },
                          icon: Icon(Icons.close, color: Theme.of(dialogContext).colorScheme.error),
                          label: Text(
                            'Reject',
                            style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Theme.of(dialogContext).colorScheme.error),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final navigator = Navigator.of(dialogContext);
                            final comment = commentController.text.trim();
                            await taskController.approveTask(
                              task.taskId,
                              reason: comment.isEmpty ? 'Approved by admin' : comment,
                            );
                            // Refresh tasks to update UI
                            await taskController.refreshTasks();
                            if (dialogContext.mounted) navigator.pop();
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(dialogContext).colorScheme.primary,
                            foregroundColor: Theme.of(dialogContext).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(BuildContext context, String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}