// widgets/task_filters_sheet.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:task/models/task_filters.dart';

class TaskFiltersSheet extends StatefulWidget {
  final TaskFilters initialFilters;
  final Function(TaskFilters) onApplyFilters;

  const TaskFiltersSheet({
    super.key,
    required this.initialFilters,
    required this.onApplyFilters,
  });

  @override
  State<TaskFiltersSheet> createState() => _TaskFiltersSheetState();
}

class _TaskFiltersSheetState extends State<TaskFiltersSheet> {
  late TaskFilters _filters;
  final TaskController _taskController = Get.find<TaskController>();
  final Set<String> _availableCategories = {};
  final Set<String> _availableTags = {};
  final Set<String> _availableStatuses = {
    'Pending',
    'In Progress',
    'Completed',
    'Archived',
  };

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
    _loadFilterOptions();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final tasks = _taskController.tasks;
      final categories = <String>{};
      final tags = <String>{};

      for (final task in tasks) {
        if (task.category?.isNotEmpty == true) {
          categories.add(task.category!);
        }
        if (task.tags.isNotEmpty == true) {
          tags.addAll(task.tags);
        }
      }

      setState(() {
        _availableCategories.addAll(categories);
        _availableTags.addAll(tags);
      });
    } catch (e) {
      debugPrint('Error loading filter options: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Tasks',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Status'),
                  _buildStatusFilter(),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Category'),
                  _buildCategoryFilter(),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Tags'),
                  _buildTagsFilter(),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Date Range'),
                  _buildDateRangeFilter(),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Assigned To'),
                  _buildAssignedToFilter(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetFilters,
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApplyFilters(_filters);
                    Navigator.pop(context);
                  },
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableStatuses.map((status) {
        final current = _filters.statuses ?? [];
        final isSelected = current.contains(status);
        return FilterChip(
          label: Text(status),
          selected: isSelected,
          onSelected: (selected) {
            final updated = selected
                ? [...current, status]
                : current.where((s) => s != status).toList();
            setState(() {
              _filters = _filters.copyWith(
                statuses: updated.isEmpty ? null : updated,
              );
            });
          },
          selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          checkmarkColor: Theme.of(context).colorScheme.primary,
        );
      }).toList(),
    );
  }

  Widget _buildCategoryFilter() {
    if (_availableCategories.isEmpty) {
      return const Text('No categories available');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableCategories.map((category) {
        final current = _filters.categories ?? [];
        final isSelected = current.contains(category);
        return FilterChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (selected) {
            final updated = selected
                ? [...current, category]
                : current.where((c) => c != category).toList();
            setState(() {
              _filters = _filters.copyWith(
                categories: updated.isEmpty ? null : updated,
              );
            });
          },
          selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          checkmarkColor: Theme.of(context).colorScheme.primary,
        );
      }).toList(),
    );
  }

  Widget _buildTagsFilter() {
    if (_availableTags.isEmpty) {
      return const Text('No tags available');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableTags.take(20).map((tag) {
        final current = _filters.tags ?? [];
        final isSelected = current.contains(tag);
        return FilterChip(
          label: Text(tag),
          selected: isSelected,
          onSelected: (selected) {
            final updated = selected
                ? [...current, tag]
                : current.where((t) => t != tag).toList();
            setState(() {
              _filters = _filters.copyWith(
                tags: updated.isEmpty ? null : updated,
              );
            });
          },
          selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          checkmarkColor: Theme.of(context).colorScheme.primary,
        );
      }).toList(),
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: const Text('From'),
          trailing: Text(
            _filters.startDate != null
                ? formatDate(_filters.startDate!)
                : 'Select date',
            style: TextStyle(
              color: _filters.startDate != null
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).hintColor,
            ),
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _filters.startDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (date != null) {
              setState(() {
                _filters = _filters.copyWith(startDate: date);
              });
            }
          },
        ),
        ListTile(
          title: const Text('To'),
          trailing: Text(
            _filters.endDate != null
                ? formatDate(_filters.endDate!)
                : 'Select date',
            style: TextStyle(
              color: _filters.endDate != null
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).hintColor,
            ),
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _filters.endDate ?? DateTime.now(),
              firstDate: _filters.startDate ?? DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (date != null) {
              setState(() {
                _filters = _filters.copyWith(endDate: date);
              });
            }
          },
        ),
        if (_filters.startDate != null || _filters.endDate != null)
          TextButton(
            onPressed: () {
              setState(() {
                _filters = _filters.copyWith(startDate: null, endDate: null);
              });
            },
            child: const Text('Clear date range'),
          ),
      ],
    );
  }

  Widget _buildAssignedToFilter() {
    return const Text(
      'User assignment filtering will be available in a future update',
      style: TextStyle(fontStyle: FontStyle.italic),
    );
  }

  void _resetFilters() {
    setState(() {
      _filters =  TaskFilters();
    });
  }

  String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
