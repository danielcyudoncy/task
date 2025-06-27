// widgets/task_details_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/widgets/dashboard_utils.dart';
import '../../controllers/admin_controller.dart';
import '../../utils/constants/app_strings.dart';


class TaskDetailsDialog extends StatelessWidget {
  final String title;
  final AdminController adminController;

  const TaskDetailsDialog({
    super.key,
    required this.title,
    required this.adminController,
  });

  @override
  Widget build(BuildContext context) {
    final doc = adminController.taskSnapshotDocs
            .firstWhereOrNull((d) => d['title'] == title) ??
        <String, dynamic>{};
    return AlertDialog(
      title: const Text(AppStrings.taskDetails),
      content: doc.isNotEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Title: $title"),
                const SizedBox(height: 6),
                Text("Status: ${doc['status'] ?? AppStrings.unknown}"),
                const SizedBox(height: 6),
                Text(
                    "Created by: ${doc['creatorName'] ?? doc['creator'] ?? 'Unknown'}"),
                const SizedBox(height: 6),
                Text("Due Date: ${formatDueDate(doc['dueDate'])}"),
              ],
            )
          : const Text("Task not found"),
      actions: [
        TextButton(
          onPressed: () {
            Get.find<SettingsController>().triggerFeedback();
            Get.back();
          },
          child: const Text(AppStrings.close),
        ),
      ],
    );
  }
}
