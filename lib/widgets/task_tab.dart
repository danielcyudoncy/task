// widgets/task_tab.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TasksTab extends StatelessWidget {
  final List<dynamic> tasks;
  final List<dynamic> taskDocs;
  final void Function(String title) onTaskTap;
  final bool isDark;

  const TasksTab({
    super.key,
    required this.tasks,
    required this.taskDocs,
    required this.onTaskTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardColor = isDark
        ? const Color(0xFF292B3A)
        : Theme.of(context).colorScheme.primary;
    const Color textColor = Colors.white;
    final Color subTextColor = isDark ? Colors.white70 : Colors.grey[600]!;
    final Color emptyListColor = isDark ? Colors.white70 : Colors.black54;

    if (tasks.isEmpty) {
      return Center(
        child: Text(
          "no_tasks".tr,
          style: TextStyle(color: emptyListColor),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final title = tasks[index];
        final doc = taskDocs.firstWhere((d) => d['title'] == title,
            orElse: () => <String, dynamic>{});

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: GestureDetector(
            onTap: () => onTaskTap(title),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black38 : const Color(0x22000000),
                    blurRadius: 8,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    doc.isNotEmpty && doc.containsKey('description')
                        ? doc['description']?.toString() ??
                            'task_details_not_available'.tr
                        : 'task_details_not_available'.tr,
                    style: TextStyle(color: subTextColor, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'assigned_to'.trParams(
                        {'name': doc['assignedName'] ?? 'unassigned'.tr}),
                    style: TextStyle(color: subTextColor, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
