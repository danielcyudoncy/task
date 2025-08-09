// features/librarian/widgets/task_list_view.dart

import 'package:flutter/material.dart';
import 'package:task/models/task_filters.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:task/models/task_model.dart';
import 'package:task/models/task_status_filter.dart';
import 'package:task/features/librarian/widgets/librarian_task_card.dart';
import 'package:task/utils/constants/app_sizes.dart';

class TaskListView extends StatefulWidget {
  final TaskStatusFilter statusFilter;
  final TaskFilters? filters;
  final String? searchQuery;
  final bool showArchived;
  final ScrollController? scrollController;
  final Function(String)? onError;

  const TaskListView({
    super.key,
    required this.statusFilter,
    this.filters,
    this.searchQuery,
    this.showArchived = false,
    this.scrollController,
    this.onError,
  });

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  final TaskController _taskController = Get.find<TaskController>();
  final RxBool _isLoading = RxBool(false); // Use RxBool for reactive boolean
  final RxString _errorMessage = RxString(''); // Use RxString for reactive string
  final RxList<Task> _tasks = RxList<Task>([]); // Use RxList for reactive list
  final RxBool _isRefreshing = RxBool(false); // Use RxBool for reactive boolean

  @override
  void initState() {
    super.initState();
    // Use SchedulerBinding to ensure first build is complete
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadTasks();
    });

    // Add listener for task updates
    _taskController.addListener(_handleTaskUpdate);
  }

  @override
  void dispose() {
    _taskController.removeListener(_handleTaskUpdate);
    super.dispose();
  }

  void _handleTaskUpdate() {
    // Only refresh if not already loading
    if (!_isLoading.value) {
      _loadTasks();
    }
  }

  @override
  void didUpdateWidget(TaskListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statusFilter != widget.statusFilter ||
        oldWidget.showArchived != widget.showArchived ||
        oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.filters != widget.filters) {
      _loadTasks();
    }
  }

  Future<void> _loadTasks() async {
    if (_isLoading.value && _isRefreshing.value) return;

    try {
      if (!_isRefreshing.value) {
        _isLoading.value = true;
      }
      _errorMessage.value = '';

      // Show loading indicator for a minimum time to prevent flicker
      final stopwatch = Stopwatch()..start();

      // Get tasks based on status filter
      List<Task> tasks = [];
try {
  switch (widget.statusFilter) {
    case TaskStatusFilter.completed:
      final allTasks = await _taskController.getAllTasks();
      tasks = allTasks.where((task) => task.status.toLowerCase() == 'completed').toList();
      break;
    case TaskStatusFilter.pending:
      // Get all tasks that are not completed
      final allTasks = await _taskController.getAllTasks();
      tasks = allTasks.where((task) => 
          task.status.toLowerCase() != 'completed').toList();
      break;
    case TaskStatusFilter.all:
      tasks = await _taskController.getAllTasks();
      break;
  }
} catch (e) {
  _errorMessage.value = 'Failed to load tasks. Please try again.';
  widget.onError?.call(_errorMessage.value);
}
      // Apply archive filter
      if (!widget.showArchived) {
        tasks = tasks.where((task) => !task.isArchived).toList();
      } else {
        tasks = tasks.where((task) => task.isArchived).toList();
      }

      // Ensure we show the loading indicator for at least 500ms
      final elapsed = stopwatch.elapsedMilliseconds;
      if (elapsed < 500) {
        await Future.delayed(Duration(milliseconds: 500 - elapsed));
      }

      // Apply search query filter
      if (widget.searchQuery?.isNotEmpty == true) {
        final query = widget.searchQuery!.toLowerCase();
        tasks = tasks.where((task) {
          return task.title.toLowerCase().contains(query) ||
              task.description.toLowerCase().contains(query) ||
              (task.category?.toLowerCase().contains(query) ?? false) ||
              task.tags.any((tag) => tag.toLowerCase().contains(query)) ||
              (task.assignedReporter?.toLowerCase().contains(query) ?? false) ||
              (task.assignedCameraman?.toLowerCase().contains(query) ?? false) ||
              (task.assignedDriver?.toLowerCase().contains(query) ?? false) ||
              (task.assignedLibrarian?.toLowerCase().contains(query) ?? false);
        }).toList();
      }

      // Apply additional filters
      if (widget.filters != null) {
        tasks = _applyFilters(tasks, widget.filters!);
      }

      _tasks.value = tasks; // Assign the filtered tasks to the RxList
    } catch (e) {
      if (_errorMessage.value.isEmpty) {
        _errorMessage.value = 'An unexpected error occurred: $e';
      }

      // Call the onError callback if provided
      widget.onError?.call(_errorMessage.value);

      if (mounted) {
        Get.snackbar(
          'Error',
          _errorMessage.value,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      _isLoading.value = false;
      _isRefreshing.value = false;
    }
  }

  List<Task> _applyFilters(List<Task> tasks, TaskFilters filters) {
    if (!filters.hasActiveFilters) {
      return tasks;
    }

    return tasks.where((task) {
      // Status filter
      if (filters.statuses?.isNotEmpty == true) {
        if (!filters.statuses!.any((status) =>
            task.status.toLowerCase() == status.toLowerCase())) {
          return false;
        }
      }

      // Category filter
      if (filters.categories?.isNotEmpty == true && task.category != null) {
        if (!filters.categories!.any((category) =>
            task.category!.toLowerCase() == category.toLowerCase())) {
          return false;
        }
      }

      // Tags filter
      if (filters.tags?.isNotEmpty == true) {
        if (task.tags.isEmpty || !filters.tags!.any((tag) =>
            task.tags.any((taskTag) =>
                taskTag.toLowerCase().trim() == tag.toLowerCase().trim()))) {
          return false;
        }
      }

      // Date range filter
      if (filters.startDate != null || filters.endDate != null) {
        if (filters.startDate != null &&
            task.timestamp.isBefore(filters.startDate!)) {
          return false;
        }
        if (filters.endDate != null &&
            task.timestamp.isAfter(filters.endDate!.add(const Duration(days: 1)))) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        if (_isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        } else if (_errorMessage.value.isNotEmpty) {
          return Center(child: Text(_errorMessage.value));
        } else if (_tasks.isEmpty) {
          return const Center(child: Text('No tasks found.'));
        } else {
          return ListView.builder(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: _tasks.length,
            itemBuilder: (context, index) {
              final task = _tasks[index];
              return LibrarianTaskCard(task: task);
            },
          );
        }
      },
    );
  }
}
