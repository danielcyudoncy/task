// controllers/performance_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/task_model.dart';

class PerformanceController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Observable variables
  var isLoading = false.obs;
  var userPerformanceData = <Map<String, dynamic>>[].obs;
  var totalUsers = 0.obs;
  var averageCompletionRate = 0.0.obs;
  var topPerformers = <Map<String, dynamic>>[].obs;
  
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
      totalUsers.value = users.length;
      
      // Fetch all tasks
      final tasksSnapshot = await _firestore.collection('tasks').get();
      final tasks = tasksSnapshot.docs.map((doc) => Task.fromMap(doc.data(), doc.id)).toList();
      
      List<Map<String, dynamic>> performanceList = [];
      double totalCompletionRate = 0.0;
      
      for (var userDoc in users) {
        final userData = userDoc.data();
        final userId = userDoc.id;
        final userName = userData['name'] ?? 'Unknown';
        final userRole = userData['role'] ?? 'Unknown';
        final userEmail = userData['email'] ?? '';
        
        // Calculate user performance metrics
        final userMetrics = await _calculateUserMetrics(userId, tasks);
        
        final performanceData = {
          'userId': userId,
          'userName': userName,
          'userRole': userRole,
          'userEmail': userEmail,
          'completedTasks': userMetrics['completedTasks'],
          'totalAssignedTasks': userMetrics['totalAssignedTasks'],
          'completionRate': userMetrics['completionRate'],
          'averageCompletionTime': userMetrics['averageCompletionTime'],
          'recentActivity': userMetrics['recentActivity'],
          'performanceGrade': _calculatePerformanceGrade(userMetrics['completionRate']),
        };
        
        performanceList.add(performanceData);
        totalCompletionRate += userMetrics['completionRate'];
      }
      
      // Sort by completion rate for top performers
      performanceList.sort((a, b) => b['completionRate'].compareTo(a['completionRate']));
      
      userPerformanceData.value = performanceList;
      averageCompletionRate.value = users.isNotEmpty ? totalCompletionRate / users.length : 0.0;
      topPerformers.value = performanceList.take(5).toList();
      
    } catch (e) {
      print('Error fetching user performance data: $e');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<Map<String, dynamic>> _calculateUserMetrics(String userId, List<Task> allTasks) async {
    // Filter tasks assigned to this user
    final assignedTasks = allTasks.where((task) => 
      task.assignedReporterId == userId ||
      task.assignedCameramanId == userId ||
      task.assignedDriverId == userId ||
      task.assignedLibrarianId == userId
    ).toList();
    
    // Filter completed tasks by this user
    final completedTasks = assignedTasks.where((task) => 
      task.completedByUserIds.contains(userId) == true
    ).toList();
    
    final totalAssigned = assignedTasks.length;
    final totalCompleted = completedTasks.length;
    final completionRate = totalAssigned > 0 ? (totalCompleted / totalAssigned) * 100 : 0.0;
    
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
      'totalAssignedTasks': totalAssigned,
      'completionRate': completionRate,
      'averageCompletionTime': averageCompletionTime,
      'recentActivity': recentCompletedTasks,
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