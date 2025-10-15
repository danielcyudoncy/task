// features/librarian/widgets/task_search_delegate.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:task/models/task.dart';

class TaskSearchDelegate extends SearchDelegate<String> {
  final TaskController _taskController = Get.find<TaskController>();

  @override
  String get searchFieldLabel => 'Search tasks...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildTaskResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildTaskResults(context);
  }

  Widget _buildTaskResults(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Text(
          'Type to search tasks',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return FutureBuilder<List<Task>>(
      future: _taskController.getAllTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final tasks = snapshot.data ?? [];
        final results = tasks.where((task) {
          final q = query.toLowerCase();
          return task.title.toLowerCase().contains(q) ||
              (task.description.toLowerCase().contains(q)) ||
              (task.category?.toLowerCase().contains(q) ?? false) ||
              task.tags.any((tag) => tag.toLowerCase().contains(q));
        }).toList();

        if (results.isEmpty) {
          return Center(
            child: Text(
              'No tasks found for "$query"',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }

        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final task = results[index];
            return ListTile(
              title: _highlightMatch(task.title, query, context),
              subtitle: task.description.isNotEmpty
                  ? _highlightMatch(task.description, query, context)
                  : null,
              trailing: Text(task.status),
              onTap: () => close(context, task.title),
            );
          },
        );
      },
    );
  }

  Widget _highlightMatch(String text, String query, BuildContext context) {
    if (query.isEmpty) return Text(text);
    final matches = text.toLowerCase().split(query.toLowerCase());
    if (matches.length < 2) return Text(text);
    final spans = <TextSpan>[];
    int start = 0;
    for (int i = 0; i < matches.length; i++) {
      final part = matches[i];
      if (part.isNotEmpty) {
        spans.add(TextSpan(text: text.substring(start, start + part.length)));
        start += part.length;
      }
      if (i < matches.length - 1) {
        spans.add(TextSpan(
          text: text.substring(start, start + query.length),
          style: TextStyle(
            backgroundColor:
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
            fontWeight: FontWeight.bold,
          ),
        ));
        start += query.length;
      }
    }
    return RichText(
        text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium, children: spans));
  }
}
