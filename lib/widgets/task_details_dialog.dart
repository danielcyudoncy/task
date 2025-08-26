// widgets/task_details_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/widgets/dashboard_utils.dart';
import '../../controllers/admin_controller.dart';
import '../models/report_completion_info.dart';
import 'package:intl/intl.dart';


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
                const SizedBox(height: 6),
                // Display completion comments if task is completed
                if (doc['status']?.toString().toLowerCase() == 'completed' && doc['reportCompletionInfo'] != null)
                  _buildCompletionComments(doc['reportCompletionInfo']),
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

  Widget _buildCompletionComments(Map<String, dynamic> reportCompletionInfo) {
    if (reportCompletionInfo.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Completion Details:',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...reportCompletionInfo.entries.map((entry) {
          final userId = entry.key;
          final completionData = entry.value as Map<String, dynamic>;
          final completionInfo = ReportCompletionInfo.fromMap(completionData);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reporter: $userId',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Has Aired: ${completionInfo.hasAired ? "Yes" : "No"}'),
                 if (completionInfo.airTime != null) ...[
                   const SizedBox(height: 2),
                   Text('Air Time: ${DateFormat('MMM dd, yyyy HH:mm').format(completionInfo.airTime!)}'),
                 ],
                 if (completionInfo.videoEditorName != null && completionInfo.videoEditorName!.isNotEmpty) ...[
                   const SizedBox(height: 2),
                   Text('Video Editor: ${completionInfo.videoEditorName}'),
                 ],
                 if (completionInfo.comments != null && completionInfo.comments!.isNotEmpty) ...[
                   const SizedBox(height: 4),
                   Text(
                     'Comments:',
                     style: const TextStyle(fontWeight: FontWeight.w500),
                   ),
                   const SizedBox(height: 2),
                   Text(
                     completionInfo.comments!,
                     style: TextStyle(
                       color: Colors.grey[700],
                       fontStyle: FontStyle.italic,
                     ),
                   ),
                 ]
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
