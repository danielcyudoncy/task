// features/librarian/widgets/task_filters_sheet.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:task/models/task_filters.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:task/controllers/user_controller.dart';
import 'package:task/widgets/chip_input_field.dart';

class TaskFiltersSheet extends StatefulWidget {
  final TaskFilters initialFilters;
  
  const TaskFiltersSheet({
    super.key,
    required this.initialFilters,
  });

  @override
  State<TaskFiltersSheet> createState() => _TaskFiltersSheetState();
}

class _TaskFiltersSheetState extends State<TaskFiltersSheet> {
  late TaskFilters _filters;
  final TaskController _taskController = Get.find<TaskController>();
  final UserController _userController = Get.find<UserController>();
  final RxList<String> _availableCategories = <String>[].obs;
  final RxList<String> _availableTags = <String>[].obs;
  final RxList<Map<String, dynamic>> _availableUsers = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;
  
  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
    _loadFilterOptions();
  }
  
  Future<void> _loadFilterOptions() async {
    try {
      _isLoading.value = true;
      
      // Load categories and tags from tasks
      final tasks = await _taskController.getAllTasks();
      
      // Extract unique categories
      final categories = tasks
          .map((task) => task.category)
          .whereType<String>()
          .toSet()
          .toList();
      
      // Extract unique tags
      final tags = <String>{};
      for (final task in tasks) {
        tags.addAll(task.tags);
      }
      
      // Load users from UserController's allUsers observable
      final users = _userController.allUsers;
      
      _availableCategories.value = categories;
      _availableTags.value = tags.toList();
      _availableUsers.value = users
          .map((user) => {
                'id': user['id'] as String,
                'name': user['name'] as String? ?? 'Unknown User',
                'email': user['email'] as String? ?? '',
                'role': user['role'] as String? ?? 'user',
              })
          .toList();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load filter options: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }
  
  Future<void> _selectDateRange(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: _filters.startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      end: _filters.endDate ?? DateTime.now(),
    );
    
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Theme.of(context).scaffoldBackgroundColor,
              onSurface: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _filters = _filters.copyWith(
          startDate: picked.start,
          endDate: picked.end,
        );
      });
    }
  }
  
  void _toggleStatus(String status) {
    setState(() {
      final statuses = _filters.statuses?.toList() ?? [];
      if (statuses.contains(status)) {
        statuses.remove(status);
      } else {
        statuses.add(status);
      }
      _filters = _filters.copyWith(statuses: statuses);
    });
  }
  
  void _toggleCategory(String category) {
    setState(() {
      final categories = _filters.categories?.toList() ?? [];
      if (categories.contains(category)) {
        categories.remove(category);
      } else {
        categories.add(category);
      }
      _filters = _filters.copyWith(categories: categories);
    });
  }
  
  void _addTag(String tag) {
    setState(() {
      final tags = _filters.tags?.toList() ?? [];
      if (!tags.contains(tag)) {
        tags.add(tag);
        _filters = _filters.copyWith(tags: tags);
      }
    });
  }
  
  void _removeTag(String tag) {
    setState(() {
      final tags = _filters.tags?.toList() ?? [];
      tags.remove(tag);
      _filters = _filters.copyWith(tags: tags);
    });
  }
  
  void _toggleUser(String userId) {
    setState(() {
      final userIds = _filters.assignedToUserIds?.toList() ?? [];
      if (userIds.contains(userId)) {
        userIds.remove(userId);
      } else {
        userIds.add(userId);
      }
      _filters = _filters.copyWith(assignedToUserIds: userIds);
    });
  }
  
  void _resetFilters() {
    setState(() {
      _filters = TaskFilters();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateRangeText = _filters.startDate != null || _filters.endDate != null
        ? '${_filters.startDate != null ? DateFormat('MMM d, y').format(_filters.startDate!) : 'Start'} - ${_filters.endDate != null ? DateFormat('MMM d, y').format(_filters.endDate!) : 'End'}'
        : 'Any date';
    
    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Tasks',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _filters.hasActiveFilters ? _resetFilters : null,
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Content
          Expanded(
            child: Obx(() {
              if (_isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status filter
                    _buildSectionTitle('Status'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildFilterChip(
                          label: 'Pending',
                          selected: _filters.statuses?.contains('Pending') ?? false,
                          onSelected: (_) => _toggleStatus('Pending'),
                        ),
                        _buildFilterChip(
                          label: 'In Progress',
                          selected: _filters.statuses?.contains('In Progress') ?? false,
                          onSelected: (_) => _toggleStatus('In Progress'),
                        ),
                        _buildFilterChip(
                          label: 'Completed',
                          selected: _filters.statuses?.contains('Completed') ?? false,
                          onSelected: (_) => _toggleStatus('Completed'),
                        ),
                        _buildFilterChip(
                          label: 'Archived',
                          selected: _filters.statuses?.contains('Archived') ?? false,
                          onSelected: (_) => _toggleStatus('Archived'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Date range filter
                    _buildSectionTitle('Date Range'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDateRange(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.dividerColor.withOpacity(0.5),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              dateRangeText,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const Spacer(),
                            if (_filters.startDate != null || _filters.endDate != null)
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _filters = _filters.copyWith(
                                      startDate: null,
                                      endDate: null,
                                    );
                                  });
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                iconSize: 18,
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Categories filter
                    _buildSectionTitle('Categories'),
                    const SizedBox(height: 8),
                    if (_availableCategories.isEmpty)
                      _buildEmptyState('No categories available')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableCategories
                            .map((category) => _buildFilterChip(
                                  label: category,
                                  selected: _filters.categories?.contains(category) ?? false,
                                  onSelected: (_) => _toggleCategory(category),
                                ))
                            .toList(),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Tags filter
                    _buildSectionTitle('Tags'),
                    const SizedBox(height: 8),
                    if (_availableTags.isEmpty)
                      _buildEmptyState('No tags available')
                    else
                      ChipInputField<String>(
                        initialItems: _filters.tags?.toList() ?? [],
                        availableSuggestions: _availableTags
                            .where((tag) =>
                                !_filters.tags!.any((selectedTag) =>
                                    selectedTag.toLowerCase() == tag.toLowerCase()))
                            .toList(),
                        itemBuilder: (context, tag) {
                          return Chip(
                            label: Text(tag),
                            onDeleted: () => _removeTag(tag),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            backgroundColor: theme.colorScheme.primaryContainer,
                            labelStyle: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          );
                        },
                        suggestionBuilder: (context, tag) {
                          return ListTile(
                            title: Text(tag),
                            onTap: () => _addTag(tag),
                          );
                        },
                        onChanged: (tags) {
                          setState(() {
                            _filters = _filters.copyWith(tags: tags);
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Add tags...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: theme.dividerColor.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: theme.dividerColor.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: theme.primaryColor,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Assigned users filter
                    _buildSectionTitle('Assigned To'),
                    const SizedBox(height: 8),
                    if (_availableUsers.isEmpty)
                      _buildEmptyState('No users available')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableUsers
                            .map((user) => _buildUserChip(
                                  user: user,
                                  selected: _filters.assignedToUserIds
                                          ?.contains(user['id']) ??
                                      false,
                                  onSelected: (_) => _toggleUser(user['id']),
                                ))
                            .toList(),
                      ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              );
            }),
          ),
          
          // Footer with apply button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: theme.dividerColor),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(_filters),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.primaryColor,
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
    );
  }
  
  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: selected
            ? Theme.of(context).primaryColor
            : Theme.of(context).dividerColor,
      ),
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.1),
      labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: selected
                ? Theme.of(context).primaryColor
                : Theme.of(context).textTheme.bodySmall?.color,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
  
  Widget _buildUserChip({
    required Map<String, dynamic> user,
    required bool selected,
    required ValueChanged<bool> onSelected,
  }) {
    final theme = Theme.of(context);
    final name = user['name'] ?? 'Unknown User';
    final email = user['email'] ?? '';
    final role = user['role'] ?? 'user';
    
    Color getRoleColor() {
      switch (role.toLowerCase()) {
        case 'admin':
          return Colors.red;
        case 'editor':
          return Colors.blue;
        case 'librarian':
          return Colors.purple;
        case 'reporter':
          return Colors.green;
        case 'cameraman':
          return Colors.orange;
        case 'driver':
          return Colors.teal;
        default:
          return theme.primaryColor;
      }
    }
    
    return Tooltip(
      message: '$name\n$email\nRole: $role',
      child: FilterChip(
        label: Text(name.split(' ').first),
        selected: selected,
        onSelected: onSelected,
        backgroundColor: Colors.transparent,
        side: BorderSide(
          color: selected ? getRoleColor() : theme.dividerColor,
        ),
        selectedColor: getRoleColor().withOpacity(0.1),
        labelStyle: theme.textTheme.bodySmall?.copyWith(
          color: selected ? getRoleColor() : theme.textTheme.bodySmall?.color,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
        avatar: CircleAvatar(
          backgroundColor: getRoleColor().withOpacity(0.2),
          radius: 12,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: theme.textTheme.labelSmall?.copyWith(
              color: getRoleColor(),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
    );
  }
  
  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).hintColor,
              fontStyle: FontStyle.italic,
            ),
      ),
    );
  }
}
