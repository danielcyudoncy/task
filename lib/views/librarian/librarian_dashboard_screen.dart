// views/librarian/librarian_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/widgets/task_list_tab.dart';

class LibrarianDashboardScreen extends StatefulWidget {
  const LibrarianDashboardScreen({super.key});

  @override
  State<LibrarianDashboardScreen> createState() => _LibrarianDashboardScreenState();
}

class _LibrarianDashboardScreenState extends State<LibrarianDashboardScreen> with SingleTickerProviderStateMixin {
  final TaskController _taskController = Get.find<TaskController>();
  final AuthController _authController = Get.find<AuthController>();
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      _taskController.fetchTasks();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load tasks: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Archive'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Completed'),
            Tab(text: 'Pending'),
            Tab(text: 'Archived'),
          ],
          labelColor: colorScheme.onPrimary,
          indicatorColor: colorScheme.onPrimary,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: TaskSearchDelegate(_taskController, _authController),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Completed Tasks Tab
          TaskListTab(
            isCompleted: true,
            isDark: theme.brightness == Brightness.dark,
            tasks: _taskController.tasks
                .where((task) =>
                    task.status == 'Completed' &&
                    (task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        task.description.toLowerCase().contains(_searchQuery.toLowerCase())))
                .toList(),
          ),
          // Pending Tasks Tab
          TaskListTab(
            isCompleted: false,
            isDark: theme.brightness == Brightness.dark,
            tasks: _taskController.tasks
                .where((task) =>
                    task.status != 'Completed' &&
                    task.status != 'Archived' &&
                    (task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        task.description.toLowerCase().contains(_searchQuery.toLowerCase())))
                .toList(),
          ),
          // Archived Tasks Tab
          TaskListTab(
            isCompleted: true,
            isDark: theme.brightness == Brightness.dark,
            tasks: _taskController.tasks
                .where((task) =>
                    task.status == 'Archived' &&
                    (task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        task.description.toLowerCase().contains(_searchQuery.toLowerCase())))
                .toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement export functionality
          _showExportOptions(context);
        },
        child: const Icon(Icons.upload_file),
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Export Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement CSV export
                Navigator.pop(context);
                Get.snackbar('Export', 'Exporting to CSV...');
              },
              child: const Text('Export as CSV'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement PDF export
                Navigator.pop(context);
                Get.snackbar('Export', 'Exporting to PDF...');
              },
              child: const Text('Export as PDF'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskSearchDelegate extends SearchDelegate {
  final TaskController taskController;
  final AuthController authController;

  TaskSearchDelegate(this.taskController, this.authController);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = taskController.tasks.where((task) {
      final searchLower = query.toLowerCase();
      return task.title.toLowerCase().contains(searchLower) ||
          task.description.toLowerCase().contains(searchLower) ||
          (task.tags.any((tag) => tag.toLowerCase().contains(searchLower))) ||
          task.category?.toLowerCase().contains(searchLower) == true;
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final task = results[index];
        return ListTile(
          title: Text(task.title),
          subtitle: Text(task.description),
          onTap: () {
            // TODO: Navigate to task details
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
