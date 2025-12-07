// screens/performance/user_performance_details_screen.dart
import 'package:flutter/foundation.dart';
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
  State<UserPerformanceDetailsScreen> createState() =>
      _UserPerformanceDetailsScreenState();
}

// Performance calculation cache
class _PerformanceCache {
  static final Map<String, PerformanceMetrics> _cache = {};

  static PerformanceMetrics? get(
      String userId, List<QueryDocumentSnapshot> tasks) {
    final key = '$userId-${tasks.length}-${tasks.hashCode}';
    return _cache[key];
  }

  static void set(String userId, List<QueryDocumentSnapshot> tasks,
      PerformanceMetrics metrics) {
    final key = '$userId-${tasks.length}-${tasks.hashCode}';
    _cache[key] = metrics;
  }

  static void clear() {
    _cache.clear();
  }
}

class PerformanceMetrics {
  final double completionRate;
  final double performanceScore;
  final String performanceGrade;
  final Map<String, int> taskStatistics;

  PerformanceMetrics({
    required this.completionRate,
    required this.performanceScore,
    required this.performanceGrade,
    required this.taskStatistics,
  });
}

class _UserPerformanceDetailsScreenState
    extends State<UserPerformanceDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PerformanceController _performanceController =
      Get.find<PerformanceController>();
  final ThemeController _themeController = Get.find<ThemeController>();
  int _refreshRetryCount = 0;
  int _errorRetryCount = 0;

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
    // Don't refresh data immediately - let the controller handle its own data loading
    // The controller will already have data from previous loads
  }

  @override
  void dispose() {
    _PerformanceCache.clear();
    super.dispose();
  }

  // Optimized performance calculation using caching and isolates
  Future<PerformanceMetrics> _calculatePerformanceMetricsCached(
    List<QueryDocumentSnapshot> tasks,
  ) async {
    // Check cache first
    final cached = _PerformanceCache.get(widget.userId, tasks);
    if (cached != null) {
      return cached;
    }

    // Use isolate for heavy computation if available
    try {
      final metrics = await compute(_calculatePerformanceMetrics, tasks);
      _PerformanceCache.set(widget.userId, tasks, metrics);
      return metrics;
    } catch (e) {
      // Fallback to main thread if isolate fails
      return _calculatePerformanceMetricsSync(tasks);
    }
  }

  // Heavy computation moved to isolate
  static PerformanceMetrics _calculatePerformanceMetrics(
      List<QueryDocumentSnapshot> tasks) {
    if (tasks.isEmpty) {
      return PerformanceMetrics(
        completionRate: 0.0,
        performanceScore: 0.0,
        performanceGrade: 'N/A',
        taskStatistics: {
          'completed': 0,
          'inProgress': 0,
          'pending': 0,
          'overdue': 0,
        },
      );
    }

    int completedTasks = 0;
    int inProgressTasks = 0;
    int pendingTasks = 0;
    int overdueTasks = 0;
    int totalScore = 0;
    final maxPossibleScore = tasks.length * 10;

    for (final task in tasks) {
      final data = task.data() as Map<String, dynamic>?;
      final status = data?['status'] as String? ?? '';

      // Count task status
      switch (status) {
        case 'Completed':
          completedTasks++;
          totalScore += 10; // Full points
          break;
        case 'In Progress':
          inProgressTasks++;
          totalScore += 7; // 70% for in-progress
          break;
        case 'Pending':
        case 'Assigned':
          pendingTasks++;
          totalScore += 3; // 30% for pending
          break;
      }

      // Check for overdue tasks
      try {
        final dueDateValue = data?['dueDate'];
        DateTime? dueDate;
        if (dueDateValue is Timestamp) {
          dueDate = dueDateValue.toDate();
        } else if (dueDateValue is String) {
          dueDate = DateTime.tryParse(dueDateValue);
        }

        if (dueDate != null &&
            status != 'Completed' &&
            dueDate.isBefore(DateTime.now())) {
          overdueTasks++;
        }
      } catch (e) {
        // Ignore parsing errors
      }
    }

    final completionRate = (completedTasks / tasks.length) * 100.0;
    final performanceScore = (totalScore / maxPossibleScore) * 10.0;
    final performanceGrade = _calculateGrade(completionRate);

    return PerformanceMetrics(
      completionRate: completionRate,
      performanceScore: performanceScore,
      performanceGrade: performanceGrade,
      taskStatistics: {
        'completed': completedTasks,
        'inProgress': inProgressTasks,
        'pending': pendingTasks,
        'overdue': overdueTasks,
      },
    );
  }

  // Synchronous fallback for main thread
  PerformanceMetrics _calculatePerformanceMetricsSync(
      List<QueryDocumentSnapshot> tasks) {
    return _calculatePerformanceMetrics(tasks);
  }

  static String _calculateGrade(double completionRate) {
    if (completionRate >= 90) return 'A+';
    if (completionRate >= 80) return 'A';
    if (completionRate >= 70) return 'B+';
    if (completionRate >= 60) return 'B';
    if (completionRate >= 50) return 'C+';
    if (completionRate >= 40) return 'C';
    return 'D';
  }

  // Optimized method to get user tasks with minimal processing
  Future<List<QueryDocumentSnapshot>> _getUserTasks() async {
    final quarterDates = _quarterDates[widget.quarter]!;
    final snapshot = await _firestore
        .collection('tasks')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(quarterDates['start']!))
        .where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(quarterDates['end']!))
        .get();

    // Filter tasks for this user (done once here instead of every build)
    final assignmentFields = [
      'assignedReporterId',
      'assignedCameramanId',
      'assignedDriverId',
      'assignedLibrarianId',
    ];

    final userTaskDocs = snapshot.docs.where((doc) {
      final data = doc.data();
      return assignmentFields.any((field) {
            final assignedUserId = data[field] as String?;
            return assignedUserId == widget.userId;
          }) ||
          data['assignedTo'] == widget.userId;
    }).toList();

    return userTaskDocs;
  }

  Widget _buildUserInfoCard(
    BuildContext context,
    String? photoUrl,
    String displayName,
    String userRole,
    String? email,
    String? phone,
    Map<String, DateTime> quarterDates,
    DateFormat dateFormat,
  ) {
    return Card(
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
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }

  Widget _buildPerformanceSection(
    BuildContext context,
    List<QueryDocumentSnapshot> userTasks,
    PerformanceMetrics? metrics,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _getPerformanceOverviewHeaderColor(context),
                fontFamily: 'Raleway',
              ),
        ),
        const SizedBox(height: 8),
        if (metrics != null)
          _buildPerformanceOverviewOptimized(context, userTasks, metrics)
        else
          const CircularProgressIndicator(),
      ],
    );
  }

  Widget _buildPerformanceOverviewOptimized(
    BuildContext context,
    List<QueryDocumentSnapshot> userTasks,
    PerformanceMetrics metrics,
  ) {
    return Card(
      color: _getCardBackgroundColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatistic('Total Tasks', '${userTasks.length}'),
                _buildStatistic(
                    'Completed', '${metrics.taskStatistics['completed']}'),
                _buildStatistic('Completion Rate',
                    '${metrics.completionRate.toStringAsFixed(1)}%'),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value:
                  userTasks.isNotEmpty ? (metrics.completionRate / 100) : 0.0,
              minHeight: 10,
              backgroundColor: _getStatisticBarColor(
                  context, _getPerformanceColor(metrics.completionRate)),
              color: _getPerformanceColor(metrics.completionRate),
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Performance Score: ${metrics.performanceScore.toStringAsFixed(1)}/10',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _getPerformanceOverviewTextColor(context),
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getGradeColor(metrics.performanceGrade),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Grade: ${metrics.performanceGrade}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildTaskStatisticsOptimized(
    BuildContext context,
    PerformanceMetrics metrics,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Task Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _getTaskStatisticsHeaderColor(context),
                fontFamily: 'Raleway',
              ),
        ),
        const SizedBox(height: 8),
        Card(
          color: _getCardBackgroundColor(context),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildStatisticRow(
                    'Completed',
                    metrics.taskStatistics['completed'] ?? 0,
                    metrics.taskStatistics['completed']! +
                        metrics.taskStatistics['inProgress']! +
                        metrics.taskStatistics['pending']! +
                        metrics.taskStatistics['overdue']!,
                    Colors.green),
                _buildStatisticRow(
                    'In Progress',
                    metrics.taskStatistics['inProgress'] ?? 0,
                    metrics.taskStatistics['completed']! +
                        metrics.taskStatistics['inProgress']! +
                        metrics.taskStatistics['pending']! +
                        metrics.taskStatistics['overdue']!,
                    Colors.blue),
                _buildStatisticRow(
                    'Pending',
                    metrics.taskStatistics['pending'] ?? 0,
                    metrics.taskStatistics['completed']! +
                        metrics.taskStatistics['inProgress']! +
                        metrics.taskStatistics['pending']! +
                        metrics.taskStatistics['overdue']!,
                    Colors.orange),
                _buildStatisticRow(
                    'Overdue',
                    metrics.taskStatistics['overdue'] ?? 0,
                    metrics.taskStatistics['completed']! +
                        metrics.taskStatistics['inProgress']! +
                        metrics.taskStatistics['pending']! +
                        metrics.taskStatistics['overdue']!,
                    Colors.red),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityOptimized(
    BuildContext context,
    List<QueryDocumentSnapshot> userTasks,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: _getRecentActivityHeaderColor(context),
                fontFamily: 'Raleway',
              ),
        ),
        const SizedBox(height: 8),
        Card(
          color: _getCardBackgroundColor(context),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: userTasks.length,
            itemBuilder: (context, index) {
              final task = userTasks[index];
              final data = task.data() as Map<String, dynamic>? ?? {};
              final title = data['title'] as String? ?? 'No Title';
              final status = data['status'] as String? ?? 'Unknown';

              return ListTile(
                title: Text(
                  title,
                  style: TextStyle(color: _getRecentActivityTextColor(context)),
                ),
                subtitle: Text(
                  'Status: $status',
                  style: TextStyle(color: _getRecentActivityTextColor(context)),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: _getRecentActivityTextColor(context),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final quarterDates = _quarterDates[widget.quarter]!;
    final dateFormat = DateFormat('MMM d, y');

    return DefaultTextStyle(
      style: DefaultTextStyle.of(context).style,
      child: Scaffold(
        key: ValueKey(_refreshRetryCount),
        appBar: AppBar(
          title: FutureBuilder<DocumentSnapshot>(
            key: ValueKey(_errorRetryCount),
            future: _firestore.collection('users').doc(widget.userId).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text(
                  'Loading...',
                  style: TextStyle(color: _getAccentTextColor(context)),
                );
              }

              if (snapshot.hasError) {
                return Text(
                    '${widget.userName}\'s Q${widget.quarter} Performance');
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Text(
                    '${widget.userName}\'s Q${widget.quarter} Performance');
              }

              final userData = snapshot.data!.data() as Map<String, dynamic>?;
              final displayName =
                  userData?['displayName']?.toString() ?? widget.userName;

              return Center(
                  child: Text('$displayName - Q${widget.quarter} Performance'));
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _refreshRetryCount++;
                });
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
              return _buildErrorWidget(
                  'Error loading user data: ${userSnapshot.error}');
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return Center(
                child: Text(
                  'User data not found',
                  style: TextStyle(color: _getAccentTextColor(context)),
                ),
              );
            }

            final userData =
                userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
            final String displayName =
                userData['displayName'] ?? widget.userName;
            final String userRole =
                userData['role']?.toString().toUpperCase() ?? 'NO ROLE';
            final String? photoUrl = userData['photoUrl'] as String?;
            final String? email = userData['email'] as String?;
            final String? phone = userData['phone'] as String?;

            return FutureBuilder<List<QueryDocumentSnapshot>>(
              future: _getUserTasks(),
              builder: (context, taskSnapshot) {
                if (taskSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (taskSnapshot.hasError) {
                  return _buildErrorWidget(
                      'Error loading tasks: ${taskSnapshot.error}');
                }

                final userTasks = taskSnapshot.data ?? [];

                return FutureBuilder<PerformanceMetrics>(
                  future: _calculatePerformanceMetricsCached(userTasks),
                  builder: (context, metricsSnapshot) {
                    if (metricsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final metrics = metricsSnapshot.data;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User Info Card
                          _buildUserInfoCard(context, photoUrl, displayName,
                              userRole, email, phone, quarterDates, dateFormat),

                          const SizedBox(height: 16),

                          // Performance Overview
                          _buildPerformanceSection(context, userTasks, metrics),

                          const SizedBox(height: 24),

                          // Task Statistics
                          if (metrics != null)
                            _buildTaskStatisticsOptimized(context, metrics),

                          const SizedBox(height: 24),

                          // Recent Activity (optimized to show only latest 10)
                          _buildRecentActivityOptimized(
                              context, userTasks.take(10).toList()),

                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
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

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: _themeController.isDarkMode.value
                ? Colors.red[300]!
                : Colors.red,
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
            onPressed: () => setState(() {
              _errorRetryCount++;
            }),
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
    return _themeController.isDarkMode.value ? Colors.white : Colors.white;
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
