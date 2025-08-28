import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/controllers/performance_controller.dart';

class UserPerformanceDetailsScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final int quarter;

  

  const UserPerformanceDetailsScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.quarter,
  });

  

  @override
  State<UserPerformanceDetailsScreen> createState() => _UserPerformanceDetailsScreenState();
}

class _UserPerformanceDetailsScreenState extends State<UserPerformanceDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PerformanceController _performanceController = Get.find<PerformanceController>();
  final AuthController _authController = Get.find<AuthController>();
  
  // Quarter date ranges
  final Map<int, Map<String, DateTime>> _quarterDates = {
    1: {
      'start': DateTime(DateTime.now().year, 1, 1),
      'end': DateTime(DateTime.now().year, 3, 31),
    },
    2: {
      'start': DateTime(DateTime.now().year, 4, 1),
      'end': DateTime(DateTime.now().year, 6, 30),
    },
    3: {
      'start': DateTime(DateTime.now().year, 7, 1),
      'end': DateTime(DateTime.now().year, 9, 30),
    },
    4: {
      'start': DateTime(DateTime.now().year, 10, 1),
      'end': DateTime(DateTime.now().year, 12, 31),
    },
  };

  @override
  Widget build(BuildContext context) {
    final quarterDates = _quarterDates[widget.quarter]!;
    final dateFormat = DateFormat('MMM d, y');

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.userName}\'s Q${widget.quarter} Performance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh data
              setState(() {});
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(widget.userId).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) {
            return Center(child: Text('Error: ${userSnapshot.error}'));
          }

          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final userRole = userData['role'] ?? 'No Role';
          final photoUrl = userData['photoUrl'] as String?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: photoUrl != null
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl == null
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userName,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(userRole),
                            Text(
                              'Q${widget.quarter} ${quarterDates['start']!.year}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${dateFormat.format(quarterDates['start']!)} - ${dateFormat.format(quarterDates['end']!)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Performance Overview
                Text(
                  'Performance Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                _buildPerformanceOverview(),

                const SizedBox(height: 24),
                
                // Task Statistics
                Text(
                  'Task Statistics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                _buildTaskStatistics(),

                const SizedBox(height: 24),
                
                // Recent Activity
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                _buildRecentActivity(),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPerformanceOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('tasks')
              .where('assignedTo', isEqualTo: widget.userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final tasks = snapshot.data!.docs;
            final completedTasks = tasks.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'Completed';
            }).length;

            final completionRate = tasks.isNotEmpty ? (completedTasks / tasks.length) * 100.0 : 0.0;
            final performanceScore = _calculatePerformanceScore(tasks);

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatistic('Total Tasks', '${tasks.length}'),
                    _buildStatistic('Completed', '$completedTasks'),
                    _buildStatistic('Completion Rate', '${completionRate.toStringAsFixed(1)}%'),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: completionRate / 100,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                  color: _getPerformanceColor(completionRate),
                ),
                const SizedBox(height: 8),
                Text(
                  'Performance Score: ${performanceScore.toStringAsFixed(1)}/10',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTaskStatistics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('tasks')
              .where('assignedTo', isEqualTo: widget.userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final tasks = snapshot.data!.docs;
            final completedTasks = tasks.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'Completed';
            }).toList();

            final inProgressTasks = tasks.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'In Progress';
            }).toList();

            final pendingTasks = tasks.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'Pending' || data['status'] == 'Assigned';
            }).toList();

            final overdueTasks = tasks.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
              final status = data['status'] as String?;
              return dueDate != null && 
                     status != 'Completed' && 
                     dueDate.isBefore(DateTime.now());
            }).toList();

            return Column(
              children: [
                _buildStatisticRow('Completed', completedTasks.length, tasks.length, Colors.green),
                _buildStatisticRow('In Progress', inProgressTasks.length, tasks.length, Colors.blue),
                _buildStatisticRow('Pending', pendingTasks.length, tasks.length, Colors.orange),
                _buildStatisticRow('Overdue', overdueTasks.length, tasks.length, Colors.red),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('tasks')
            .where('assignedTo', isEqualTo: widget.userId)
            .orderBy('updatedAt', descending: true)
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data!.docs;
          
          if (tasks.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No recent activity found.'),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final data = task.data() as Map<String, dynamic>;
              final title = data['title'] as String? ?? 'No Title';
              final status = data['status'] as String? ?? 'Unknown';
              final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate();
              
              return ListTile(
                title: Text(title),
                subtitle: Text('Status: $status'),
                trailing: Text(
                  updatedAt != null 
                    ? DateFormat('MMM d, y').format(updatedAt)
                    : 'N/A',
                ),
                onTap: () {
                  // Navigate to task details if needed
                  // Get.to(() => TaskDetailsScreen(taskId: task.id));
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatistic(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildStatisticRow(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total) * 100 : 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$label: $count',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: count / (total == 0 ? 1 : total),
            backgroundColor: color.withOpacity(0.2),
            color: color,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  double _calculatePerformanceScore(List<QueryDocumentSnapshot> tasks) {
    if (tasks.isEmpty) return 0.0;
    
    int totalScore = 0;
    int maxPossibleScore = tasks.length * 10; // Max 10 points per task
    
    for (final task in tasks) {
      final data = task.data() as Map<String, dynamic>;
      final status = data['status'] as String? ?? '';
      final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
      final completedAt = (data['completedAt'] as Timestamp?)?.toDate();
      
      // Base score based on status
      int taskScore = 0;
      
      switch (status.toLowerCase()) {
        case 'completed':
          taskScore = 10; // Full points for completed tasks
          
          // Bonus for early completion, penalty for late completion
          if (dueDate != null && completedAt != null) {
            if (completedAt.isBefore(dueDate)) {
              taskScore += 2; // Bonus for early completion
            } else if (completedAt.isAfter(dueDate)) {
              taskScore -= 3; // Penalty for late completion
            }
          }
          break;
          
        case 'in progress':
          taskScore = 5; // Half points for in-progress tasks
          
          // Check if task is approaching deadline
          if (dueDate != null) {
            final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
            if (daysUntilDue < 0) {
              taskScore -= 2; // Penalty for overdue tasks
            } else if (daysUntilDue <= 2) {
              taskScore += 1; // Small bonus for tasks due soon
            }
          }
          break;
          
        case 'pending':
        case 'assigned':
          taskScore = 2; // Minimal points for pending/assigned tasks
          
          // Check if task is overdue
          if (dueDate != null && DateTime.now().isAfter(dueDate)) {
            taskScore = 0; // No points for overdue tasks
          }
          break;
          
        default:
          taskScore = 0;
      }
      
      // Ensure score is within bounds
      taskScore = taskScore.clamp(0, 10);
      totalScore += taskScore;
    }
    
    // Calculate average score out of 10
    return (totalScore / tasks.length).clamp(0.0, 10.0);
  }

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }
}
