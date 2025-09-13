// controllers/performance_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/task_model.dart';

class PerformanceController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Observable variables
  final isLoading = false.obs;
  final userPerformanceData = <Map<String, dynamic>>[].obs;
  final totalUsers = 0.obs;
  final averageCompletionRate = 0.0.obs;
  // New metrics
  final averageCompletionRateWeighted = 0.0.obs;
  final averageCompletionRateExcludingZero = 0.0.obs;
  final topPerformers = <Map<String, dynamic>>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    fetchUserPerformanceData();
  }
  
  Future<void> fetchUserPerformanceData() async {
    try {
      isLoading.value = true;
      
      // Fetch all users
      final usersSnapshot = await _firestore.collection('users').get();
      final users = usersSnapshot.docs;
      // Count users excluding librarians
      totalUsers.value = users.where((doc) {
        final userData = doc.data();
        final userRole = userData['role'] ?? 'Unknown';
        return userRole != 'Librarian';
      }).length;
      
      // Fetch all tasks
      final tasksSnapshot = await _firestore.collection('tasks').get();
      final tasks = tasksSnapshot.docs.map((doc) {
        final data = doc.data();
        data['taskId'] = doc.id;
        return Task.fromMap(data);
      }).toList();
      
      final performanceList = <Map<String, dynamic>>[];
      
      for (var userDoc in users) {
        final userData = userDoc.data();
        final userId = userDoc.id;
        final userName = userData['fullName'] ?? userData['fullname'] ?? userData['name'] ?? 'Unknown User';
        final userRole = userData['role'] ?? 'Unknown';
        final userEmail = userData['email'] ?? '';
        
        // Skip librarians and admins from performance tracking
        if (userRole == 'Librarian' || userRole == 'Admin') {
          continue;
        }
        
        // Calculate user performance metrics
        final userMetrics = _calculateUserMetrics(userId, userName, tasks);
        
        final performanceData = {
          'userId': userId,
          'userName': userName,
          'userRole': userRole,
          'userEmail': userEmail,
          'photoUrl': userData['photoUrl'] ?? '',
          'completedTasks': userMetrics['completedTasks'],
          'inProgressTasks': userMetrics['inProgressTasks'],
          'overdueTasks': userMetrics['overdueTasks'],
          'totalAssignedTasks': userMetrics['totalAssignedTasks'],
          'completionRate': userMetrics['completionRate'],
          'averageCompletionTime': userMetrics['averageCompletionTime'],
          'recentActivity': userMetrics['recentActivity'],
          'performanceGrade': _calculatePerformanceGrade(userMetrics['completionRate']),
        };
        
        performanceList.add(performanceData);
      }
      
      // Sort by completion rate for top performers
      performanceList.sort((a, b) =>
          (b['completionRate'] as double).compareTo(a['completionRate'] as double));

      // Compute alternative averages
      final withAssigned = performanceList.where((u) => (u['totalAssignedTasks'] as int) > 0).toList();
      final totalAssignedAll = withAssigned.fold<int>(0, (acc, u) => acc + (u['totalAssignedTasks'] as int));
      final totalCompletedAll = withAssigned.fold<int>(0, (acc, u) => acc + (u['completedTasks'] as int));
      final weightedAvg = totalAssignedAll > 0 ? (totalCompletedAll / totalAssignedAll) * 100.0 : 0.0;
      final meanExcludingZero = withAssigned.isNotEmpty
          ? withAssigned.fold<double>(0.0, (acc, u) => acc + (u['completionRate'] as double)) / withAssigned.length
          : 0.0;
      
      userPerformanceData.value = performanceList;
      // Expose both new metrics
      averageCompletionRateWeighted.value = weightedAvg;
      averageCompletionRateExcludingZero.value = meanExcludingZero;
      // Backwards-compatible default now uses weighted average
      averageCompletionRate.value = weightedAvg;
      topPerformers.value = performanceList.take(5).toList();
      
        } catch (e, stackTrace) {
      Get.log('PerformanceController: fetchUserPerformanceData error: $e', isError: true);
      Get.log(stackTrace.toString(), isError: true);
    } finally {
      isLoading.value = false;
    }
  }
  
  Map<String, dynamic> _calculateUserMetrics(String userId, String userName, List<Task> allTasks) {
    // Constants for quarter-based marking
    const int quarterDays = 90;
    const double percentPerDay = 100.0 / quarterDays; // ≈ 1.111...% per day

    // Filter tasks assigned to this user (excluding librarian assignments)
    final assignedTasks = allTasks.where((task) => 
      task.assignedReporterId == userId ||
      task.assignedCameramanId == userId ||
      task.assignedDriverId == userId ||
      // Legacy/general assignment fallback
      task.assignedTo == userId ||
      // Name-based fallbacks (older records stored names instead of IDs)
      (task.assignedReporter != null && task.assignedReporter == userName) ||
      (task.assignedCameraman != null && task.assignedCameraman == userName) ||
      (task.assignedDriver != null && task.assignedDriver == userName)
    ).toList();
    
    // Filter completed tasks by this user
    final completedTasks = assignedTasks.where((task) {
      final completedByUser = task.completedByUserIds.contains(userId);
      // Fallback for legacy data: overall completed implies completion for assigned users
      final overallCompleted = task.status.toLowerCase() == 'completed';
      return completedByUser || overallCompleted;
    }).toList();
    
    // Filter in-progress tasks (assigned but not completed by this user)
    final inProgressTasks = assignedTasks.where((task) => 
      !task.completedByUserIds.contains(userId) && 
      task.status.toLowerCase() != 'completed'
    ).toList();
    
    // Filter overdue tasks (in-progress tasks past due date)
    final now = DateTime.now();
    final overdueTasks = inProgressTasks.where((task) => 
      task.dueDate != null && task.dueDate!.isBefore(now)
    ).toList();
    
    final totalAssigned = assignedTasks.length;
    final totalCompleted = completedTasks.length;
    final totalInProgress = inProgressTasks.length;
    final totalOverdue = overdueTasks.length;
    final completionRate = totalAssigned > 0 ? (totalCompleted / totalAssigned) * 100 : 0.0;

    // Quarter-based mark per completed task = daysRemainingInQuarter * (100/90)
    // If no dueDate, treat remaining days as 0 (no mark) to avoid inflating scores.
    double sumTaskMarks = 0.0;
    for (final task in completedTasks) {
      final due = task.dueDate; // using due date as the end target within quarter
      if (due != null) {
        // Days remaining: if completion time available, compare completion to quarter end approximation.
        // Approximate a 90-day quarter window ending at due date; earlier completion => more remaining days.
        final completionTime = task.userCompletionTimestamps[userId] ?? task.timestamp;
        final daysElapsed = completionTime.difference(task.timestamp).inDays;
        final daysRemaining = quarterDays - daysElapsed;
        final clampedRemaining = daysRemaining.clamp(0, quarterDays);
        final taskMark = clampedRemaining * percentPerDay;
        sumTaskMarks += taskMark;
      }
    }
    final double quarterMark = totalCompleted > 0 ? sumTaskMarks / totalCompleted : 0.0;
    
    // Calculate average completion time
    double averageCompletionTime = 0.0;
    if (completedTasks.isNotEmpty) {
      double totalTime = 0.0;
      int validTimes = 0;
      
      for (var task in completedTasks) {
        if (task.userCompletionTimestamps.containsKey(userId)) {
          final completionTime = task.userCompletionTimestamps[userId]!;
          final creationTime = task.timestamp;
          final timeDiff = completionTime.difference(creationTime).inHours;
          if (timeDiff > 0) {
            totalTime += timeDiff;
            validTimes++;
          }
        }
      }
      
      averageCompletionTime = validTimes > 0 ? totalTime / validTimes : 0.0;
    }
    
    // Check recent activity (tasks completed in last 30 days)
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentCompletedTasks = completedTasks.where((task) => 
      task.userCompletionTimestamps.containsKey(userId) &&
      task.userCompletionTimestamps[userId]!.isAfter(thirtyDaysAgo)
    ).length;
    
    return {
      'completedTasks': totalCompleted,
      'inProgressTasks': totalInProgress,
      'overdueTasks': totalOverdue,
      'totalAssignedTasks': totalAssigned,
      'completionRate': completionRate,
      'averageCompletionTime': averageCompletionTime,
      'recentActivity': recentCompletedTasks,
      // Quarter scoring outputs
      'quarterMark': quarterMark, // average per-task mark for this user
      'sumTaskMarks': sumTaskMarks, // sum of marks for all completed tasks
    };
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
  
  List<Map<String, dynamic>> getUsersByRole(String role) {
    return userPerformanceData.where((user) => user['userRole'] == role).toList();
  }
  
  List<Map<String, dynamic>> getUsersByPerformanceGrade(String grade) {
    return userPerformanceData.where((user) => user['performanceGrade'] == grade).toList();
  }
  
  Map<String, int> getPerformanceDistribution() {
    Map<String, int> distribution = {
      'A+': 0, 'A': 0, 'B+': 0, 'B': 0, 'C+': 0, 'C': 0, 'D': 0
    };
    
    for (var user in userPerformanceData) {
      final grade = user['performanceGrade'] as String;
      distribution[grade] = (distribution[grade] ?? 0) + 1;
    }
    
    return distribution;
  }
  
  void refreshData() {
    fetchUserPerformanceData();
  }
}