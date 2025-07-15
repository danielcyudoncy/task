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
