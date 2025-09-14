// views/performance/user_performance_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:task/controllers/performance_controller.dart';
import 'package:task/controllers/theme_controller.dart';

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
  final ThemeController _themeController = Get.find<ThemeController>();
  
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
  void initState() {
    super.initState();
    // Refresh performance data when screen loads
    _performanceController.refreshData();
  }

  @override
  Widget build(BuildContext context) {
    final quarterDates = _quarterDates[widget.quarter]!;
    final dateFormat = DateFormat('MMM d, y');

    return DefaultTextStyle(
      style: DefaultTextStyle.of(context).style,
      child: Scaffold(
        appBar: AppBar(
          title: FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('users').doc(widget.userId).get(),
            builder: (context, snapshot) {
              
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text(
                  'Loading...',
                  style: TextStyle(color: _getAccentTextColor(context)),
                );
              }
              
              if (snapshot.hasError) {
                
                return Text('${widget.userName}\'s Q${widget.quarter} Performance');
              }
              
              if (!snapshot.hasData || !snapshot.data!.exists) {
                
                return Text('${widget.userName}\'s Q${widget.quarter} Performance');
              }
              
              final userData = snapshot.data!.data() as Map<String, dynamic>?;
             
              
              userData?['displayName']?.toString();
             
              
              return Center(child: Text('Q${widget.quarter} Performance'));
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {});
                _performanceController.refreshData();
              },
            ),
            
          ],
        ),
        body: FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('users').doc(widget.userId).get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (userSnapshot.hasError) {
              return _buildErrorWidget('Error loading user data: ${userSnapshot.error}');
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return Center(
                child: Text(
                  'User data not found',
                  style: TextStyle(color: _getAccentTextColor(context)),
                ),
              );
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
            final String displayName = userData['displayName'] ?? widget.userName;
            final String userRole = userData['role']?.toString().toUpperCase() ?? 'NO ROLE';
            final String? photoUrl = userData['photoUrl'] as String?;
            final String? email = userData['email'] as String?;
            final String? phone = userData['phone'] as String?;

            return StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('tasks')
                  .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(_quarterDates[widget.quarter]!['start']!))
                  .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(_quarterDates[widget.quarter]!['end']!))
                  .snapshots(),
              builder: (context, taskSnapshot) {
                if (taskSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (taskSnapshot.hasError) {
                  return _buildErrorWidget('Error loading tasks: ${taskSnapshot.error}');
                }

                // Filter tasks for this user
                final assignmentFields = [
                  'assignedReporterId',
                  'assignedCameramanId',
                  'assignedDriverId',
                  'assignedLibrarianId',
                ];

                final allTasks = taskSnapshot.hasData ? taskSnapshot.data!.docs : <QueryDocumentSnapshot>[];
                final userTasks = allTasks.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return assignmentFields.any((field) {
                    final assignedUserId = data[field] as String?;
                    return assignedUserId == widget.userId;
                  }) || data['assignedTo'] == widget.userId;
                }).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Info Card
                      Card(
                        color: _getCardBackgroundColor(context),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: _getAvatarBackgroundColor(context),
                                child: photoUrl != null && photoUrl.isNotEmpty
                                    ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: photoUrl,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => const CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                          errorWidget: (context, url, error) => const Icon(
                                            Icons.person,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      )
                                    : const Icon(Icons.person, size: 40, color: Colors.grey),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _getAccentTextColor(context),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getRoleBadgeBackgroundColor(context),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        userRole,
                                        style: TextStyle(
                                          color: _getRoleBadgeTextColor(context),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ),
                                    if (email != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        email,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: _getAccentTextColor(context),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    if (phone != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        phone,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      'Q${widget.quarter} ${quarterDates['start']!.year}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: _getAccentTextColor(context),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${dateFormat.format(quarterDates['start']!)} - ${dateFormat.format(quarterDates['end']!)}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: _getAccentTextColor(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Performance Overview
                      Text(
                        'Performance Overview',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: _getPerformanceOverviewHeaderColor(context), fontFamily: 'Raleway'
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPerformanceOverview(userTasks),

                      const SizedBox(height: 24),
                      
                      // Task Statistics
                      Text(
                        'Task Statistics',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: _getTaskStatisticsHeaderColor(context), fontFamily: 'Raleway'
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildTaskStatistics(userTasks),

                      const SizedBox(height: 24),
                      
                      // Recent Activity
                      Text(
                        'Recent Activity',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: _getRecentActivityHeaderColor(context),
                          fontFamily: 'Raleway',
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRecentActivity(userTasks),

                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPerformanceOverview(List<QueryDocumentSnapshot> tasks) {
    // Get user performance data from controller if available
    final userPerformanceData = _performanceController.userPerformanceData
        .firstWhereOrNull((user) => user['userId'] == widget.userId);

    final completedTasks = tasks.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      return data?['status'] == 'Completed';
    }).toList();

    final completionRate = tasks.isNotEmpty 
        ? (completedTasks.length / tasks.length) * 100.0 
        : 0.0;
    final performanceScore = _calculatePerformanceScore(tasks);

    // Use performance grade from controller if available
    final performanceGrade = userPerformanceData?['performanceGrade'] ?? 
        _calculatePerformanceGrade(completionRate);

    return Card(
      color: _getCardBackgroundColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatistic('Total Tasks', '${tasks.length}'),
                _buildStatistic('Completed', '${completedTasks.length}'),
                _buildStatistic('Completion Rate', '${completionRate.toStringAsFixed(1)}%'),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: tasks.isNotEmpty ? (completionRate / 100) : 0.0,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
              color: _getPerformanceColor(completionRate),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Performance Score: ${performanceScore.toStringAsFixed(1)}/10',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _getPerformanceOverviewTextColor(context),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getGradeColor(performanceGrade),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Grade: $performanceGrade',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStatistics(List<QueryDocumentSnapshot> userTasks) {
    // Calculate task statistics from the provided userTasks

    final completedTasks = userTasks.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      return data?['status'] == 'Completed';
    }).toList();

    final inProgressTasks = userTasks.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      return data?['status'] == 'In Progress';
    }).toList();

    final pendingTasks = userTasks.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      return data?['status'] == 'Pending' || data?['status'] == 'Assigned';
    }).toList();

    final overdueTasks = userTasks.where((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      DateTime? dueDate;
      try {
        final dueDateValue = data?['dueDate'];
        if (dueDateValue is Timestamp) {
          dueDate = dueDateValue.toDate();
        } else if (dueDateValue is String) {
          dueDate = DateTime.tryParse(dueDateValue);
        }
      } catch (e) {
        dueDate = null;
      }
      final status = data?['status'] as String?;
      return dueDate != null && 
             status != 'Completed' && 
             dueDate.isBefore(DateTime.now());
    }).toList();

    return Card(
      color: _getCardBackgroundColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatisticRow('Completed', completedTasks.length, userTasks.length, Colors.green),
            _buildStatisticRow('In Progress', inProgressTasks.length, userTasks.length, Colors.blue),
            _buildStatisticRow('Pending', pendingTasks.length, userTasks.length, Colors.orange),
            _buildStatisticRow('Overdue', overdueTasks.length, userTasks.length, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(List<QueryDocumentSnapshot> userTasks) {
    // Display recent activity from the provided userTasks

    if (userTasks.isEmpty) {
      return Card(
        color: _getCardBackgroundColor(context),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No recent activity found',
              style: TextStyle(color: _getRecentActivityTextColor(context)),
            ),
          ),
        ),
      );
    }

    // Sort tasks by updatedAt in descending order
    final sortedTasks = List<QueryDocumentSnapshot>.from(userTasks);
    sortedTasks.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      
      DateTime aUpdatedAt = DateTime(1970);
      DateTime bUpdatedAt = DateTime(1970);
      
      try {
        final aValue = aData['updatedAt'];
        if (aValue is Timestamp) {
          aUpdatedAt = aValue.toDate();
        } else if (aValue is String) {
          aUpdatedAt = DateTime.tryParse(aValue) ?? DateTime(1970);
        }
      } catch (e) {
        aUpdatedAt = DateTime(1970);
      }
      
      try {
        final bValue = bData['updatedAt'];
        if (bValue is Timestamp) {
          bUpdatedAt = bValue.toDate();
        } else if (bValue is String) {
          bUpdatedAt = DateTime.tryParse(bValue) ?? DateTime(1970);
        }
      } catch (e) {
        bUpdatedAt = DateTime(1970);
      }
      
      return bUpdatedAt.compareTo(aUpdatedAt);
    });

    return Card(
      color: _getCardBackgroundColor(context),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedTasks.length,
        itemBuilder: (context, index) {
          final task = sortedTasks[index];
          final data = task.data() as Map<String, dynamic>? ?? {};
          final title = data['title'] as String? ?? 'No Title';
          final status = data['status'] as String? ?? 'Unknown';
          DateTime? updatedAt;
           try {
             final updatedAtValue = data['updatedAt'];
             if (updatedAtValue is Timestamp) {
               updatedAt = updatedAtValue.toDate();
             } else if (updatedAtValue is String) {
               updatedAt = DateTime.tryParse(updatedAtValue);
             }
           } catch (e) {
             updatedAt = null;
           }
          
          return ListTile(
            title: Text(
              title,
              style: TextStyle(color: _getRecentActivityTextColor(context)),
            ),
            subtitle: Text(
              'Status: $status',
              style: TextStyle(color: _getRecentActivityTextColor(context)),
            ),
            trailing: Text(
              updatedAt != null 
                ? DateFormat('MMM d, y').format(updatedAt)
                : 'N/A',
              style: TextStyle(color: _getRecentActivityTextColor(context)),
            ),
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
            color: _getAccentTextColor(context),
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: _getAccentTextColor(context),
          ),
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _getTaskStatisticsTextColor(context),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _getTaskStatisticsTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: count / (total == 0 ? 1 : total),
            backgroundColor: _getStatisticBarColor(context, color),
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
      DateTime? dueDate;
      DateTime? completedAt;
      
      try {
        final dueDateValue = data['dueDate'];
        if (dueDateValue is Timestamp) {
          dueDate = dueDateValue.toDate();
        } else if (dueDateValue is String) {
          dueDate = DateTime.tryParse(dueDateValue);
        }
      } catch (e) {
        dueDate = null;
      }
      
      try {
        final completedAtValue = data['completedAt'];
        if (completedAtValue is Timestamp) {
          completedAt = completedAtValue.toDate();
        } else if (completedAtValue is String) {
          completedAt = DateTime.tryParse(completedAtValue);
        }
      } catch (e) {
        completedAt = null;
      }
      
      // Base score based on status
      int taskScore = 0;
      
      switch (status) {
        case 'Completed':
          taskScore = 10; // Full points for completed tasks
          break;
        case 'In Progress':
          taskScore = 7; // 70% for in-progress tasks
          break;
        case 'Pending':
        case 'Assigned':
          taskScore = 3; // 30% for pending/assigned tasks
          break;
        default:
          taskScore = 0; // No points for other statuses
      }
      
      // Bonus points for early completion
      if (status == 'Completed' && dueDate != null && completedAt != null) {
        if (completedAt.isBefore(dueDate)) {
          taskScore += 2; // 2 bonus points for early completion
        } else if (completedAt.isAfter(dueDate)) {
          taskScore = (taskScore * 0.8).round(); // 20% penalty for late completion
        }
      }
      
      // Ensure score is within 0-10 range
      taskScore = taskScore.clamp(0, 10);
      totalScore += taskScore;
    }
    
    // Calculate final score as a percentage of max possible score
    final double finalScore = (totalScore / maxPossibleScore) * 10;
    return finalScore;
  }

  Color _getPerformanceColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return Colors.green;
      case 'B+':
      case 'B':
        return Colors.blue;
      case 'C+':
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _calculatePerformanceGrade(double completionRate) {
    if (completionRate >= 90) return 'A+';
    if (completionRate >= 80) return 'A';
    if (completionRate >= 70) return 'B+';
    if (completionRate >= 60) return 'B';
    if (completionRate >= 50) return 'C+';
    if (completionRate >= 40) return 'C';
    return 'D';
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline, 
            color: _themeController.isDarkMode.value ? Colors.red[300]! : Colors.red, 
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16, 
              color: _getAccentTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  // Theme-aware color methods
   Color _getCardBackgroundColor(BuildContext context) {
      return _themeController.isDarkMode.value
          ? const Color(0xFF2D2D2D) // Gradient grey for dark mode
          : const Color(0xFF002060); // Specific dark blue for light mode
    }

  Color _getAvatarBackgroundColor(BuildContext context) {
     return _themeController.isDarkMode.value
         ? Theme.of(context).primaryColor.withValues(alpha: 0.3)
         : Colors.white;
   }

  Color _getRoleBadgeBackgroundColor(BuildContext context) {
     return _themeController.isDarkMode.value
         ? Theme.of(context).primaryColor
         : Colors.white.withValues(alpha: 0.9);
   }

  Color _getRoleBadgeTextColor(BuildContext context) {
     return _themeController.isDarkMode.value
         ? Colors.white
         : const Color(0xFF002060);
   }

  Color _getAccentTextColor(BuildContext context) {
     return _themeController.isDarkMode.value
         ? Colors.white
         : Colors.white;
   }

  // Colors for section headers (on white/light backgrounds)
  Color _getPerformanceOverviewHeaderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF002060);
  }

  Color _getTaskStatisticsHeaderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF002060);
  }

  Color _getRecentActivityHeaderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF002060);
  }

  // Colors for text inside cards (on dark blue backgrounds)
  Color _getPerformanceOverviewTextColor(BuildContext context) {
    return Colors.white;
  }

  Color _getTaskStatisticsTextColor(BuildContext context) {
    return Colors.white;
  }

  Color _getRecentActivityTextColor(BuildContext context) {
    return Colors.white;
  }

  Color _getStatisticBarColor(BuildContext context, Color baseColor) {
    return _themeController.isDarkMode.value
        ? baseColor.withValues(alpha: 0.8)
        : baseColor.withValues(alpha: 0.2);
  }
}