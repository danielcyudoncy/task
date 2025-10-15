// features/librarian/screens/archived_tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:task/models/task.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

class ArchivedTasksScreen extends StatefulWidget {
  const ArchivedTasksScreen({super.key});

  @override
  State<ArchivedTasksScreen> createState() => _ArchivedTasksScreenState();
}

class _ArchivedTasksScreenState extends State<ArchivedTasksScreen> {
  final TaskController _taskController = Get.find<TaskController>();
  List<Task> _archivedTasks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadArchivedTasks();
  }

  Future<void> _loadArchivedTasks() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final tasks = await _taskController.getAllTasks();

      final archivedTasks = tasks.where((task) => task.isArchived).toList();

      // Sort by archived date (most recent first)
      archivedTasks.sort((a, b) {
        if (a.archivedAt == null && b.archivedAt == null) return 0;
        if (a.archivedAt == null) return 1;
        if (b.archivedAt == null) return -1;
        return b.archivedAt!.compareTo(a.archivedAt!);
      });

      setState(() {
        _archivedTasks = archivedTasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived Tasks'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? [Colors.grey[900]!, Colors.grey[800]!]
                .reduce((value, element) => value)
            : Theme.of(context).colorScheme.primary,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadArchivedTasks,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? [Colors.grey[900]!, Colors.grey[800]!]
                  .reduce((value, element) => value)
              : Theme.of(context).colorScheme.primary,
        ),
        child: _buildBody(context, theme, colorScheme),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading archived tasks',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadArchivedTasks,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_archivedTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.archive_outlined,
              size: 64,
              color: colorScheme.onPrimary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Archived Tasks',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tasks that are archived will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadArchivedTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _archivedTasks.length,
        itemBuilder: (context, index) {
          final task = _archivedTasks[index];
          return _buildArchivedTaskCard(context, theme, colorScheme, task);
        },
      ),
    );
  }

  Widget _buildArchivedTaskCard(BuildContext context, ThemeData theme,
      ColorScheme colorScheme, Task task) {
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDark ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDark
            ? BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task title and status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.archive,
                        size: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Archived',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Task description
            if (task.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  task.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Archive details
            _buildArchiveDetails(context, theme, colorScheme, task),
          ],
        ),
      ),
    );
  }

  Widget _buildArchiveDetails(BuildContext context, ThemeData theme,
      ColorScheme colorScheme, Task task) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Archive date
          if (task.archivedAt != null)
            _buildDetailRow(
              context,
              theme,
              colorScheme,
              Icons.schedule,
              'Archived Date',
              DateFormat('MMM dd, yyyy \\at hh:mm a').format(task.archivedAt!),
            ),

          // Archive location
          if (task.archiveLocation != null && task.archiveLocation!.isNotEmpty)
            _buildDetailRow(
              context,
              theme,
              colorScheme,
              Icons.location_on_outlined,
              'Location',
              task.archiveLocation!,
            ),

          // Archived by
          if (task.archivedBy != null && task.archivedBy!.isNotEmpty)
            _buildDetailRow(
              context,
              theme,
              colorScheme,
              Icons.person_outline,
              'Archived By',
              task.archivedBy!,
            ),

          // Archive reason
          if (task.archiveReason != null && task.archiveReason!.isNotEmpty)
            _buildDetailRow(
              context,
              theme,
              colorScheme,
              Icons.info_outline,
              'Reason',
              task.archiveReason!,
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
