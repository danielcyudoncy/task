// widgets/cached_task_list.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../service/cached_task_service.dart';
import '../service/cache_manager.dart';

/// A widget that demonstrates intelligent caching with task lists
class CachedTaskList extends StatefulWidget {
  final String? userId;
  final String? status;
  final String? category;
  final bool enableRealTime;
  final VoidCallback? onTaskTap;
  
  const CachedTaskList({
    super.key,
    this.userId,
    this.status,
    this.category,
    this.enableRealTime = true,
    this.onTaskTap,
  });
  
  @override
  State<CachedTaskList> createState() => _CachedTaskListState();
}

class _CachedTaskListState extends State<CachedTaskList> {
  final CachedTaskService _taskService = Get.find<CachedTaskService>();
  final CacheManager _cacheManager = Get.find<CacheManager>();
  
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadTasks();
    _setupRealTimeUpdates();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cache status indicator
        _buildCacheStatusBar(),
        
        // Task list
        Expanded(
          child: _buildTaskList(),
        ),
      ],
    );
  }
  
  Widget _buildCacheStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cached,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'cache_status_active'.tr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Refresh button
          IconButton(
            onPressed: _isRefreshing ? null : _refreshTasks,
            icon: _isRefreshing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  )
                : Icon(
                    Icons.refresh,
                    size: 18,
                    color: Theme.of(context).primaryColor,
                  ),
            tooltip: 'refresh_tasks'.tr,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            padding: EdgeInsets.zero,
          ),
          // Cache clear button
          IconButton(
            onPressed: _clearCache,
            icon: Icon(
              Icons.clear_all,
              size: 18,
              color: Theme.of(context).colorScheme.secondary,
            ),
            tooltip: 'clear_cache'.tr,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTaskList() {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_error != null) {
      return _buildErrorState();
    }
    
    if (_tasks.isEmpty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: _refreshTasks,
      child: ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return _buildTaskCard(task);
        },
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'loading_tasks'.tr,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'error_loading_tasks'.tr,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'unknown_error'.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTasks,
            child: Text('retry'.tr),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 64,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'no_tasks_found'.tr,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'no_tasks_description'.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).disabledColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildTaskCard(Map<String, dynamic> task) {
    final title = task['title'] ?? 'untitled_task'.tr;
    final description = task['description'] ?? '';
    final status = task['status'] ?? 'pending';
    final priority = task['priority'] ?? 'medium';
    final assigneeData = task['assigneeData'] as List<Map<String, dynamic>>? ?? [];
    final creatorName = task['creatorName'] ?? 'unknown_user'.tr;
    final dueDate = task['dueDate'];
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: widget.onTaskTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(status),
                ],
              ),
              
              // Description
              if (description.isNotEmpty) const SizedBox(height: 8),
              if (description.isNotEmpty)
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              
              const SizedBox(height: 12),
              
              // Footer with assignees, creator, and due date
              Row(
                children: [
                  // Priority indicator
                  _buildPriorityIndicator(priority),
                  const SizedBox(width: 8),
                  
                  // Creator
                  Expanded(
                    child: Text(
                      'created_by'.tr.replaceAll('{name}', creatorName),
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Assignees
                  if (assigneeData.isNotEmpty) const SizedBox(width: 8),
                  if (assigneeData.isNotEmpty) _buildAssigneeAvatars(assigneeData),
                  
                  // Due date
                  if (dueDate != null) const SizedBox(width: 8),
                  if (dueDate != null) _buildDueDateChip(dueDate),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    
    switch (status.toLowerCase()) {
      case 'completed':
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green.shade700;
        break;
      case 'in_progress':
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue.shade700;
        break;
      case 'pending':
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange.shade700;
        break;
      case 'archived':
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey.shade700;
        break;
      default:
        backgroundColor = Theme.of(context).primaryColor.withValues(alpha: 0.1);
        textColor = Theme.of(context).primaryColor;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.tr,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  Widget _buildPriorityIndicator(String priority) {
    Color color;
    
    switch (priority.toLowerCase()) {
      case 'high':
        color = Colors.red;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      case 'low':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
  
  Widget _buildAssigneeAvatars(List<Map<String, dynamic>> assignees) {
    const maxVisible = 3;
    final visibleAssignees = assignees.take(maxVisible).toList();
    final remainingCount = assignees.length - maxVisible;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...visibleAssignees.map((assignee) {
          final avatar = assignee['avatar'] as String? ?? '';
          final name = assignee['name'] as String? ?? 'Unknown';
          
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
              child: avatar.isEmpty
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
          );
        }),
        
        if (remainingCount > 0)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '+$remainingCount',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).disabledColor,
                  fontSize: 10,
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildDueDateChip(dynamic dueDate) {
    DateTime? date;
    
    if (dueDate is String) {
      date = DateTime.tryParse(dueDate);
    } else if (dueDate is DateTime) {
      date = dueDate;
    }
    
    if (date == null) return const SizedBox.shrink();
    
    final now = DateTime.now();
    final isOverdue = date.isBefore(now);
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final isTomorrow = date.difference(now).inDays == 1;
    
    String text;
    Color color;
    
    if (isOverdue) {
      text = 'overdue'.tr;
      color = Colors.red;
    } else if (isToday) {
      text = 'today'.tr;
      color = Colors.orange;
    } else if (isTomorrow) {
      text = 'tomorrow'.tr;
      color = Colors.blue;
    } else {
      final days = date.difference(now).inDays;
      text = '$days ${'days'.tr}';
      color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  // Event handlers
  
  Future<void> _loadTasks() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    
    try {
      final tasks = await _taskService.getTasks(
        assignedTo: widget.userId,
        status: widget.status,
        category: widget.category,
        enableRealTime: widget.enableRealTime,
      );
      
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _refreshTasks() async {
    if (mounted) {
      setState(() {
        _isRefreshing = true;
      });
    }
    
    try {
      final tasks = await _taskService.getTasks(
        assignedTo: widget.userId,
        status: widget.status,
        category: widget.category,
        forceRefresh: true,
        enableRealTime: widget.enableRealTime,
      );
      
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isRefreshing = false;
        });
      }
    }
  }
  
  Future<void> _clearCache() async {
    try {
      await _cacheManager.invalidateAllTaskCache();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('cache_cleared'.tr),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Reload tasks after clearing cache
      await _loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_clearing_cache'.tr),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _setupRealTimeUpdates() {
    if (!widget.enableRealTime) return;
    
    // Listen to task updates
    _taskService.tasksStream.listen((tasks) {
      if (mounted) {
        setState(() {
          _tasks = tasks;
        });
      }
    });
    
    // Listen to individual task updates
    _taskService.taskUpdateStream.listen((update) {
      final action = update['action'] as String?;
      final taskId = update['taskId'] as String?;
      
      if (mounted && taskId != null) {
        switch (action) {
          case 'created':
          case 'updated':
            // Refresh the list to show updated data
            _loadTasks();
            break;
          case 'deleted':
            // Remove the task from the list
            setState(() {
              _tasks.removeWhere((task) => task['id'] == taskId);
            });
            break;
        }
      }
    });
  }
}