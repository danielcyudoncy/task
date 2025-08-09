// service/daily_task_notification_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/models/task_model.dart';

class DailyTaskNotificationService extends GetxService {
  static DailyTaskNotificationService get instance => Get.find();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Observables for real-time updates
  final RxInt todayAssignedCount = 0.obs;
  final RxInt todayCompletedCount = 0.obs;
  final RxBool hasNewAssignments = false.obs;
  final RxBool hasNewCompletions = false.obs;
  
  // Stream subscriptions
  StreamSubscription<QuerySnapshot>? _assignedTasksSubscription;
  StreamSubscription<QuerySnapshot>? _completedTasksSubscription;
  
  // Cache for previous counts to detect changes
  int _previousAssignedCount = 0;
  int _previousCompletedCount = 0;
  
  @override
  void onInit() {
    super.onInit();
    _initializeListeners();
  }
  
  @override
  void onClose() {
    _assignedTasksSubscription?.cancel();
    _completedTasksSubscription?.cancel();
    super.onClose();
  }
  
  void _initializeListeners() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    // Listen to tasks assigned today
    _assignedTasksSubscription = _firestore
        .collection('tasks')
        .where('assignmentTimestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('assignmentTimestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .listen(
      (snapshot) {
        final newCount = snapshot.docs.length;
        
        // Check if there are new assignments
        if (newCount > _previousAssignedCount && _previousAssignedCount > 0) {
          hasNewAssignments.value = true;
          _showNewAssignmentNotification(newCount - _previousAssignedCount);
        }
        
        todayAssignedCount.value = newCount;
        _previousAssignedCount = newCount;
      },
      onError: (error) {
        if (kDebugMode) {
          print('Error listening to assigned tasks: $error');
        }
      },
    );
    
    // Listen to tasks completed today
    _completedTasksSubscription = _firestore
        .collection('tasks')
        .where('status', isEqualTo: 'completed')
        .where('lastModified', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('lastModified', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .listen(
      (snapshot) {
        final newCount = snapshot.docs.length;
        
        // Check if there are new completions
        if (newCount > _previousCompletedCount && _previousCompletedCount > 0) {
          hasNewCompletions.value = true;
          _showNewCompletionNotification(newCount - _previousCompletedCount);
        }
        
        todayCompletedCount.value = newCount;
        _previousCompletedCount = newCount;
      },
      onError: (error) {
        if (kDebugMode) {
          print('Error listening to completed tasks: $error');
        }
      },
    );
  }
  
  void _showNewAssignmentNotification(int newAssignments) {
    Get.snackbar(
      '📋 New Task Assignments',
      '$newAssignments new task${newAssignments > 1 ? 's' : ''} assigned today',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      backgroundColor: Get.theme.colorScheme.primaryContainer,
      colorText: Get.theme.colorScheme.onPrimaryContainer,
      icon: const Icon(
        Icons.assignment_add,
        color: Colors.blue,
      ),
      shouldIconPulse: true,
      barBlur: 20,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }
  
  void _showNewCompletionNotification(int newCompletions) {
    Get.snackbar(
      '✅ Tasks Completed',
      '$newCompletions task${newCompletions > 1 ? 's' : ''} completed today',
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      backgroundColor: Get.theme.colorScheme.primaryContainer,
      colorText: Get.theme.colorScheme.onPrimaryContainer,
      icon: const Icon(
        Icons.check_circle,
        color: Colors.green,
      ),
      shouldIconPulse: true,
      barBlur: 20,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }
  
  /// Get daily task statistics
  Map<String, int> get dailyStats => {
    'assigned': todayAssignedCount.value,
    'completed': todayCompletedCount.value,
    'pending': todayAssignedCount.value - todayCompletedCount.value,
  };
  
  /// Get completion rate as percentage
  double get completionRate {
    if (todayAssignedCount.value == 0) return 0.0;
    return (todayCompletedCount.value / todayAssignedCount.value) * 100;
  }
  
  /// Check if there are any notifications to show
  bool get hasNotifications => hasNewAssignments.value || hasNewCompletions.value;
  
  /// Clear notification flags
  void clearNotifications() {
    hasNewAssignments.value = false;
    hasNewCompletions.value = false;
  }
  
  /// Manually refresh the listeners (useful for timezone changes or day transitions)
  void refreshListeners() {
    _assignedTasksSubscription?.cancel();
    _completedTasksSubscription?.cancel();
    _previousAssignedCount = 0;
    _previousCompletedCount = 0;
    _initializeListeners();
  }
  
  /// Get tasks assigned to a specific user today
  Future<List<Task>> getTasksAssignedToUserToday(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      final snapshot = await _firestore
          .collection('tasks')
          .where('assignmentTimestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('assignmentTimestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();
      
      final tasks = <Task>[];
      for (final doc in snapshot.docs) {
        final task = Task.fromMap(doc.data(), doc.id);
        // Check if user is assigned to this task
        if (task.assignedUserIds.contains(userId)) {
          tasks.add(task);
        }
      }
      
      return tasks;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting tasks assigned to user today: $e');
      }
      return [];
    }
  }
  
  /// Get summary for the past week
  Future<Map<String, Map<String, int>>> getWeeklySummary() async {
    try {
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      
      final snapshot = await _firestore
          .collection('tasks')
          .where('assignmentTimestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
          .where('assignmentTimestamp', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();
      
      final weeklyData = <String, Map<String, int>>{};
      
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        weeklyData[dateKey] = {'assigned': 0, 'completed': 0};
      }
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final assignmentTimestamp = data['assignmentTimestamp'] as Timestamp?;
        final status = data['status'] as String?;
        final lastModified = data['lastModified'] as Timestamp?;
        
        if (assignmentTimestamp != null) {
          final assignmentDate = assignmentTimestamp.toDate();
          final dateKey = '${assignmentDate.year}-${assignmentDate.month.toString().padLeft(2, '0')}-${assignmentDate.day.toString().padLeft(2, '0')}';
          
          if (weeklyData.containsKey(dateKey)) {
            weeklyData[dateKey]!['assigned'] = (weeklyData[dateKey]!['assigned'] ?? 0) + 1;
          }
        }
        
        if (status == 'completed' && lastModified != null) {
          final completionDate = lastModified.toDate();
          final dateKey = '${completionDate.year}-${completionDate.month.toString().padLeft(2, '0')}-${completionDate.day.toString().padLeft(2, '0')}';
          
          if (weeklyData.containsKey(dateKey)) {
            weeklyData[dateKey]!['completed'] = (weeklyData[dateKey]!['completed'] ?? 0) + 1;
          }
        }
      }
      
      return weeklyData;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting weekly summary: $e');
      }
      return {};
    }
  }
}