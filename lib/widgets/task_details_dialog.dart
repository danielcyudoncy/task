// widgets/task_details_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/widgets/dashboard_utils.dart';
import '../../controllers/admin_controller.dart';


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
      title: Text('task_details'.tr),
      content: doc.isNotEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('title'.trParams({'title': title})),
                const SizedBox(height: 6),
                Text('status'.trParams({'status': doc['status'] ?? 'unknown'.tr})),
                const SizedBox(height: 6),
                Text('created_by'.trParams({'name': doc['creatorName'] ?? doc['creator'] ?? 'unknown'.tr})),
                const SizedBox(height: 6),
                Text('due_date'.trParams({'date': formatDueDate(doc['dueDate'])})),
                const SizedBox(height: 6),
                Text('category'.trParams({'category': doc['category'] ?? 'No category'})),
                const SizedBox(height: 6),
                Text('priority'.trParams({'priority': doc['priority'] ?? 'No priority'})),
                const SizedBox(height: 6),
                Text('reporter'.trParams({'name': doc['assignedReporterName'] ?? 'Not Assigned'})),
                const SizedBox(height: 6),
                Text('cameraman'.trParams({'name': doc['assignedCameramanName'] ?? 'Not Assigned'})),
                const SizedBox(height: 6),
                Text('tags'.trParams({'tags': (doc['tags'] is List && (doc['tags'] as List).isNotEmpty) ? (doc['tags'] as List).join(', ') : 'None'})),
                const SizedBox(height: 6),
                Text('comments'.trParams({'count': (doc['comments'] is List) ? (doc['comments'] as List).length.toString() : '0'})),
              ],
            )
          : Text('task_not_found'.tr),
      actions: [
        TextButton(
          onPressed: () {
            Get.find<SettingsController>().triggerFeedback();
            Get.back();
          },
          child: Text('close'.tr),
        ),
      ],
    );
  }
}
