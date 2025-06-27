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
    final primaryBlue = theme.colorScheme.primary;
    final assignableTasks =
        widget.adminController.taskSnapshotDocs.where((task) {
      final assigned =
          task['assignedTo'] != null && task['assignedTo'].isNotEmpty;
      final completed =
          (task['status'] ?? '').toString().toLowerCase() == 'completed';
      return !assigned && !completed;
    }).toList();

    return Dialog(
      backgroundColor: isDark ? theme.colorScheme.surface : primaryBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        padding: const EdgeInsets.all(22.0),
        width: 350.w,
        child: assignableTasks.isEmpty
            ? Center(
                child: Text(
                  "No assignable tasks available",
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: Colors.white),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Title
                  Row(
                    children: [
                      const Icon(Icons.assignment_turned_in,
                          color: Colors.white, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.user != null
                              ? "Assign Task to ${widget.user?['fullName'] ?? widget.user?['fullname'] ?? ''}"
                              : "Assign Task",
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Dropdown with avatar, status icon, creator name, title, info icon
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? theme.cardColor : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: getBorderColor(theme, isDark, primaryBlue),
                        width: 1.2,
                      ),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedTaskTitle,
                        dropdownColor: isDark ? theme.cardColor : Colors.white,
                        hint: Text(
                          "Select Task",
                          style: TextStyle(
                            color:
                                isDark ? Colors.white54 : Colors.grey.shade700,
                            fontSize: 16,
                          ),
                        ),
                        icon: Icon(Icons.arrow_drop_down,
                            color: isDark ? Colors.white : primaryBlue),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 16,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        items: assignableTasks.map((task) {
                          final title = task['title'] ?? '';
                          final creatorName =
                              (task['creatorName'] ?? task['creator'] ?? '')
                                  .toString();
                          return DropdownMenuItem<String>(
                            value: title,
                            child: GestureDetector(
                              onTap: () {
                                Get.find<SettingsController>()
                                    .triggerFeedback();
                                setState(() {
                                  selectedTaskTitle = title;
                                });
                              },
                              onLongPress: () {
                                Get.find<SettingsController>()
                                    .triggerFeedback();
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text(title),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (creatorName.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 6.0),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.person,
                                                    size: 18,
                                                    color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Text(creatorName,
                                                    style: theme
                                                        .textTheme.bodyMedium),
                                              ],
                                            ),
                                          ),
                                        Text(
                                          task['description'] ??
                                              "No description",
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "Due: ${task['dueDate'] != null ? formatDueDate(task['dueDate']) : 'N/A'}",
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        child: const Text("Close"),
                                        onPressed: () {
                                          Get.find<SettingsController>()
                                              .triggerFeedback();
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  // Avatar for creator
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: getPriorityColor(task),
                                    child: Text(
                                      getCreatorInitials(task),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Creator name (if available)
                                  if (creatorName.isNotEmpty) ...[
                                    Text(
                                      creatorName,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.grey.shade800,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  // Icon for status
                                  Icon(
                                    getStatusIcon(task),
                                    color: primaryBlue,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  // Task title
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color:
                                            isDark ? Colors.white : primaryBlue,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.info_outline,
                                        color: Colors.grey.shade500, size: 18),
                                    tooltip: "Preview",
                                    onPressed: () {
                                      Get.find<SettingsController>()
                                          .triggerFeedback();
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: Text(title),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (creatorName.isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 6.0),
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.person,
                                                          size: 18,
                                                          color: Colors.grey),
                                                      const SizedBox(width: 4),
                                                      Text(creatorName,
                                                          style: theme.textTheme
                                                              .bodyMedium),
                                                    ],
                                                  ),
                                                ),
                                              Text(
                                                task['description'] ??
                                                    "No description",
                                                style:
                                                    theme.textTheme.bodyMedium,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                "Due: ${task['dueDate'] != null ? formatDueDate(task['dueDate']) : 'N/A'}",
                                                style:
                                                    theme.textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              child: const Text("Close"),
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => selectedTaskTitle = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                        onPressed: () => Get.back(),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDark ? Colors.blueAccent : Colors.white,
                          foregroundColor: isDark ? Colors.white : primaryBlue,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.check),
                        label: const Text("Assign"),
                        onPressed: () async {
                          Get.find<SettingsController>().triggerFeedback();
                          if (selectedTaskTitle == null) {
                            Get.snackbar(
                              "Error",
                              "Please select a task",
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                            return;
                          }
                          if (widget.user == null) {
                            Get.back();
                            return;
                          }
                          final userId =
                              widget.user?['uid'] ?? widget.user?['id'];
                          if (userId == null) {
                            Get.snackbar("Error", "User ID is missing");
                            return;
                          }
                          final selectedTaskDoc = assignableTasks.firstWhere(
                              (d) => d['title'] == selectedTaskTitle,
                              orElse: () => <String, dynamic>{});

                          final String taskId = selectedTaskDoc['id'] ??
                              selectedTaskDoc['taskId'];
                          final String taskDescription =
                              selectedTaskDoc['description'] ?? "";
                          final DateTime dueDate = (selectedTaskDoc['dueDate']
                                  is Timestamp)
                              ? (selectedTaskDoc['dueDate'] as Timestamp)
                                  .toDate()
                              : DateTime.tryParse(
                                      selectedTaskDoc['dueDate']?.toString() ??
                                          "") ??
                                  DateTime.now();

                          try {
                            await widget.adminController.assignTaskToUser(
                              userId: userId,
                              assignedName: widget.user?['fullName'] ??
                                  widget.user?['fullname'] ??
                                  '',
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
                            );
                          } catch (e) {
                            Get.snackbar(
                              "Error",
                              "Failed to assign task: $e",
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
