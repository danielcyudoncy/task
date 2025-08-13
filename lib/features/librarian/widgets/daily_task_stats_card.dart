// features/librarian/widgets/daily_task_stats_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/service/daily_task_notification_service.dart';

class DailyTaskStatsCard extends StatefulWidget {
  const DailyTaskStatsCard({super.key});

  @override
  State<DailyTaskStatsCard> createState() => _DailyTaskStatsCardState();
}

class _DailyTaskStatsCardState extends State<DailyTaskStatsCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  
  final DailyTaskNotificationService _notificationService = Get.find<DailyTaskNotificationService>();
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }
  
  void _onRefresh() {
    _notificationService.refreshListeners();
    _animationController.reset();
    _animationController.forward();
  }
  
  Future<void> _showWeeklySummary() async {
    try {
      final weeklySummary = await _notificationService.getWeeklySummary();
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.calendar_view_week, color: Colors.green),
              SizedBox(width: 8),
              Text('Weekly Summary'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400, // Add height constraint
            child: weeklySummary.isEmpty
                ? Text('No data available for the past week.')
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: weeklySummary.entries.map((entry) {
                        final date = entry.key;
                        final data = entry.value;
                        final assigned = data['assigned'] ?? 0;
                        final completed = data['completed'] ?? 0;
                        final pending = assigned - completed;
                        
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(date),
                            subtitle: Text('Assigned: $assigned, Completed: $completed, Pending: $pending'),
                            trailing: assigned > 0
                                ? Text('${((completed / assigned) * 100).toStringAsFixed(1)}%')
                                : Text('0%'),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to load weekly summary: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
      }
    }
  }
  
  Future<void> _showUserFilterDialog() async {
    final TextEditingController userIdController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.person_search, color: Colors.orange),
            SizedBox(width: 8),
            Text('Filter by User'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userIdController,
              decoration: InputDecoration(
                labelText: 'User ID',
                hintText: 'Enter user ID to filter tasks',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Enter a user ID to view tasks assigned to that specific user today.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final userId = userIdController.text.trim();
              if (userId.isNotEmpty) {
                Navigator.of(context).pop();
                await _showUserTasks(userId);
              }
            },
            child: Text('Filter'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showUserTasks(String userId) async {
    try {
      final userTasks = await _notificationService.getTasksAssignedToUserToday(userId);
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.assignment_ind, color: Colors.blue),
              SizedBox(width: 8),
              Text('Tasks for User: $userId'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: userTasks.isEmpty
                ? Center(child: Text('No tasks assigned to this user today.'))
                : ListView.builder(
                    itemCount: userTasks.length,
                    itemBuilder: (context, index) {
                      final task = userTasks[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(task.title),
                          subtitle: Text('Status: ${task.status}'),
                          leading: CircleAvatar(
                            backgroundColor: task.status == 'completed'
                                ? Colors.green
                                : task.status == 'in_progress'
                                    ? Colors.orange
                                    : Colors.grey,
                            child: Icon(
                              task.status == 'completed'
                                  ? Icons.check
                                  : task.status == 'in_progress'
                                      ? Icons.hourglass_empty
                                      : Icons.pending,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to load user tasks: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Obx(() {
            final hasNotifications = _notificationService.hasNotifications;
            final assignedCount = _notificationService.todayAssignedCount.value;
            final completedCount = _notificationService.todayCompletedCount.value;
            final pendingCount = _notificationService.todayPendingCount.value;
            final completionRate = _notificationService.completionRate;
            
            return AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: hasNotifications ? _pulseAnimation.value : 1.0,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: hasNotifications
                            ? [
                                Colors.blue.withValues(alpha: 0.2),
                                Colors.purple.withValues(alpha: 0.1),
                              ]
                            : [
                                Colors.blue.withValues(alpha: 0.1),
                                Colors.purple.withValues(alpha: 0.05),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hasNotifications
                            ? Colors.blue.withValues(alpha: 0.4)
                            : Colors.blue.withValues(alpha: 0.2),
                        width: hasNotifications ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: hasNotifications ? 0.2 : 0.1),
                          blurRadius: hasNotifications ? 15 : 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Daily Task Overview',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      if (hasNotifications) ...[                                         const SizedBox(width: 8),                                         Container(                                           padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),                                           decoration: BoxDecoration(                                             color: Colors.red,                                             borderRadius: BorderRadius.circular(8),                                           ),                                           child: Text(                                             'NEW',                                             style: TextStyle(
                                               color: Theme.of(context).colorScheme.onError,
                                               fontSize: 8,
                                               fontWeight: FontWeight.bold,
                                             ),                                           ),                                         ),                                       ],
                                    ],
                                  ),
                                  Text(
                                    'Real-time task updates',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                  IconButton(
                                    onPressed: () {
                                      _onRefresh();
                                      if (hasNotifications) {
                                        _notificationService.clearNotifications();
                                      }
                                    },
                                    icon: Icon(
                                      Icons.refresh,
                                      color: Colors.blue,
                                    ),
                                    tooltip: 'Quick Refresh',
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: Colors.blue,
                                    ),
                                    tooltip: 'More options',
                                    onSelected: (value) async {
                                      switch (value) {
                                        case 'weekly':
                                          await _showWeeklySummary();
                                          break;
                                        case 'user_filter':
                                          await _showUserFilterDialog();
                                          break;
                                        case 'refresh':
                                          _onRefresh();
                                          if (hasNotifications) {
                                            _notificationService.clearNotifications();
                                          }
                                          break;
                                      }
                                    },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'refresh',
                                      child: Row(
                                        children: [
                                          Icon(Icons.refresh, size: 16, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Refresh'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'weekly',
                                      child: Row(
                                        children: [
                                          Icon(Icons.calendar_view_week, size: 16, color: Colors.green),
                                          SizedBox(width: 8),
                                          Text('Weekly Summary'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'user_filter',
                                      child: Row(
                                        children: [
                                          Icon(Icons.person_search, size: 16, color: Colors.orange),
                                          SizedBox(width: 8),
                                          Text('Filter by User'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildStatItem(
                                context,
                                icon: Icons.assignment,
                                label: 'Assigned',
                                value: assignedCount,
                                color: Colors.blue,
                                hasNewData: _notificationService.hasNewAssignments.value,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 3,
                              child: _buildStatItem(
                                context,
                                icon: Icons.check_circle,
                                label: 'Completed',
                                value: completedCount,
                                color: Colors.green,
                                hasNewData: _notificationService.hasNewCompletions.value,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 2,
                              child: _buildStatItem(
                                context,
                                icon: Icons.pending,
                                label: 'Pending',
                                value: pendingCount,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        if (assignedCount > 0) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  color: Colors.grey[600],
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Completion Rate: ${completionRate.toStringAsFixed(1)}%',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  width: 60,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: completionRate / 100,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: completionRate >= 80
                                            ? Colors.green
                                            : completionRate >= 50
                                                ? Colors.orange
                                                : Colors.red,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        );
      },
    );
  }
  
  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    bool hasNewData = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: hasNewData ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: hasNewData ? 0.5 : 0.3),
          width: hasNewData ? 2 : 1,
        ),
        boxShadow: hasNewData
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              if (hasNewData)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}