// service/daily_task_notification_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/models/task.dart';
import 'package:task/controllers/auth_controller.dart';

class DailyTaskNotificationService extends GetxService {
  static DailyTaskNotificationService get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observables for real-time updates
  final RxInt todayAssignedCount = 0.obs; // Tracks tasks assigned today
  final RxInt todayCompletedCount = 0.obs; // Tracks tasks completed today
  final RxInt todayPendingCount =
      0.obs; // Tracks tasks assigned to users today but not yet completed
  final RxBool hasNewAssignments = false.obs; // Tracks new task assignments
  final RxBool hasNewCompletions = false.obs;

  // Stream subscriptions
  StreamSubscription<QuerySnapshot>? _assignedTasksSubscription;
  StreamSubscription<QuerySnapshot>? _completedTasksSubscription;
  StreamSubscription<QuerySnapshot>? _pendingTasksSubscription;
  StreamSubscription<User?>? _authSubscription;

  // Cache for previous counts to detect changes
  int _previousAssignedCount = 0; // Actually tracks tasks created today

  @override
  void onInit() {
    super.onInit();
    debugPrint('DailyTaskNotificationService: Current user: ${FirebaseAuth.instance.currentUser}');
    debugPrint('DailyTaskNotificationService: Auth state check - proceeding only if authenticated');

    // Listen to auth state changes
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        debugPrint('DailyTaskNotificationService: User authenticated, initializing listeners');
        await _initializeListeners();
      } else {
        debugPrint('DailyTaskNotificationService: No authenticated user, canceling listeners');
        _cancelListeners();
      }
    });

  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    _assignedTasksSubscription?.cancel();
    _completedTasksSubscription?.cancel();
    _pendingTasksSubscription?.cancel();
    super.onClose();
  }

  void _cancelListeners() {
    _assignedTasksSubscription?.cancel();
    _assignedTasksSubscription = null;
    _completedTasksSubscription?.cancel();
    _completedTasksSubscription = null;
    _pendingTasksSubscription?.cancel();
    _pendingTasksSubscription = null;
    debugPrint('DailyTaskNotificationService: Listeners canceled');
  }

  Future<void> _initializeListeners() async {
    // Check if user is authenticated before starting listeners
    if (FirebaseAuth.instance.currentUser == null) {
      debugPrint('DailyTaskNotificationService: No authenticated user, skipping listeners');
      return;
    }
    debugPrint('DailyTaskNotificationService: Starting listeners for authenticated user');

    final userId = FirebaseAuth.instance.currentUser!.uid;
    String userRole = Get.find<AuthController>().userRole.value; // Assuming AuthController is available
    debugPrint('DailyTaskNotificationService: Initial user role: $userRole');

    // Wait for user role to load if it's empty
    if (userRole.isEmpty) {
      debugPrint('DailyTaskNotificationService: User role is empty, waiting for it to load...');
      int attempts = 0;
      while (userRole.isEmpty && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        userRole = Get.find<AuthController>().userRole.value;
        attempts++;
      }
      if (userRole.isEmpty) {
        debugPrint('DailyTaskNotificationService: User role still empty after waiting, proceeding with empty role');
      } else {
        debugPrint('DailyTaskNotificationService: User role loaded: $userRole');
      }
    }

    debugPrint('DailyTaskNotificationService: Setting up listeners for role: $userRole');

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // For admins, use broad queries; for non-admins, use filtered queries
    if (userRole == 'Admin' || userRole == 'admin') {
      // Listen to all tasks and filter for those assigned today
      _assignedTasksSubscription =
          _firestore.collection('tasks').snapshots().listen(
      (snapshot) {
        int assignedTodayCount = 0;

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final assignedAt = data['assignedAt'];

          // Check if task was assigned today
          if (assignedAt != null) {
            DateTime? assignmentDate;
            if (assignedAt is Timestamp) {
              assignmentDate = assignedAt.toDate();
            } else if (assignedAt is String) {
              assignmentDate = DateTime.tryParse(assignedAt);
            }

            if (assignmentDate != null &&
                assignmentDate.isAfter(startOfDay) &&
                assignmentDate.isBefore(endOfDay.add(Duration(seconds: 1)))) {
              assignedTodayCount++;
            }
          }
        }

        // Check if there are new task assignments
        if (assignedTodayCount > _previousAssignedCount &&
            _previousAssignedCount > 0) {
          hasNewAssignments.value = true;
          _showNewAssignmentNotification(
              assignedTodayCount - _previousAssignedCount);
        }

        todayAssignedCount.value = assignedTodayCount;
        _previousAssignedCount = assignedTodayCount;
      },
      onError: (error) {
        if (kDebugMode) {
          print('Error listening to assigned tasks: $error');
          print('DailyTaskNotificationService: Auth state at error: ${FirebaseAuth.instance.currentUser}');
        }
      },
    );
    } else {
      // For non-admins, use filtered queries based on role
      debugPrint('DailyTaskNotificationService: Using filtered query for non-admin user');
      // Query tasks assigned to the user
      _assignedTasksSubscription =
          _firestore.collection('tasks').where('assignedUserIds', arrayContains: userId).snapshots().listen(
        (snapshot) {
          int assignedTodayCount = 0;

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final assignedAt = data['assignedAt'];

            // Check if task was assigned today
            if (assignedAt != null) {
              DateTime? assignmentDate;
              if (assignedAt is Timestamp) {
                assignmentDate = assignedAt.toDate();
              } else if (assignedAt is String) {
                assignmentDate = DateTime.tryParse(assignedAt);
              }

              if (assignmentDate != null &&
                  assignmentDate.isAfter(startOfDay) &&
                  assignmentDate.isBefore(endOfDay.add(Duration(seconds: 1)))) {
                assignedTodayCount++;
              }
            }
          }

          // Check if there are new task assignments
          if (assignedTodayCount > _previousAssignedCount &&
              _previousAssignedCount > 0) {
            hasNewAssignments.value = true;
            _showNewAssignmentNotification(
                assignedTodayCount - _previousAssignedCount);
          }

          todayAssignedCount.value = assignedTodayCount;
          _previousAssignedCount = assignedTodayCount;
        },
        onError: (error) {
          if (kDebugMode) {
            print('Error listening to assigned tasks: $error');
            print('DailyTaskNotificationService: Auth state at error: ${FirebaseAuth.instance.currentUser}');
          }
        },
      );
    }

    // Listen to tasks based on role for pending tasks
    if (userRole == 'Admin' || userRole == 'admin') {
      _pendingTasksSubscription =
          _firestore.collection('tasks').snapshots().listen(
        (snapshot) {
          int pendingTodayCount = 0;

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final assignedAt = data['assignedAt'];

            // Check if task was assigned today
            bool assignedToday = false;
            if (assignedAt != null) {
              DateTime? assignmentDate;
              if (assignedAt is Timestamp) {
                assignmentDate = assignedAt.toDate();
              } else if (assignedAt is String) {
                assignmentDate = DateTime.tryParse(assignedAt);
              }

              if (assignmentDate != null &&
                  assignmentDate.isAfter(startOfDay) &&
                  assignmentDate.isBefore(endOfDay.add(Duration(seconds: 1)))) {
                assignedToday = true;
              }
            }

            // Get all assigned user IDs first
            final assignedUserIds = <String>[];
            if (data['assignedReporterId'] != null &&
                data['assignedReporterId'].toString().isNotEmpty) {
              assignedUserIds.add(data['assignedReporterId'].toString());
            }
            if (data['assignedCameramanId'] != null &&
                data['assignedCameramanId'].toString().isNotEmpty) {
              assignedUserIds.add(data['assignedCameramanId'].toString());
            }
            if (data['assignedDriverId'] != null &&
                data['assignedDriverId'].toString().isNotEmpty) {
              assignedUserIds.add(data['assignedDriverId'].toString());
            }
            if (data['assignedLibrarianId'] != null &&
                data['assignedLibrarianId'].toString().isNotEmpty) {
              assignedUserIds.add(data['assignedLibrarianId'].toString());
            }

            // Only consider tasks that have been assigned to users and were assigned today
            if (assignedUserIds.isNotEmpty && assignedToday) {
              final status = data['status'] as String? ?? '';
              final completedByUserIds =
                  List<String>.from(data['completedByUserIds'] ?? []);

              // Check if task is pending (not completed by all assigned users)
              bool isCompleted = status.toLowerCase() == 'completed' ||
                  assignedUserIds
                      .every((userId) => completedByUserIds.contains(userId));

              if (!isCompleted) {
                pendingTodayCount++;
              }
            }
          }

          todayPendingCount.value = pendingTodayCount;
        },
        onError: (error) {
          if (kDebugMode) {
            print('Error listening to pending tasks: $error');
            print('DailyTaskNotificationService: Auth state at error: ${FirebaseAuth.instance.currentUser}');
          }
        },
      );
    } else {
      _pendingTasksSubscription =
          _firestore.collection('tasks').where('assignedUserIds', arrayContains: userId).snapshots().listen(
        (snapshot) {
          int pendingTodayCount = 0;

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final assignedAt = data['assignedAt'];

            // Check if task was assigned today
            bool assignedToday = false;
            if (assignedAt != null) {
              DateTime? assignmentDate;
              if (assignedAt is Timestamp) {
                assignmentDate = assignedAt.toDate();
              } else if (assignedAt is String) {
                assignmentDate = DateTime.tryParse(assignedAt);
              }

              if (assignmentDate != null &&
                  assignmentDate.isAfter(startOfDay) &&
                  assignmentDate.isBefore(endOfDay.add(Duration(seconds: 1)))) {
                assignedToday = true;
              }
            }

            // Get all assigned user IDs first
            final assignedUserIds = <String>[];
            if (data['assignedReporterId'] != null &&
                data['assignedReporterId'].toString().isNotEmpty) {
              assignedUserIds.add(data['assignedReporterId'].toString());
            }
            if (data['assignedCameramanId'] != null &&
                data['assignedCameramanId'].toString().isNotEmpty) {
              assignedUserIds.add(data['assignedCameramanId'].toString());
            }
            if (data['assignedDriverId'] != null &&
                data['assignedDriverId'].toString().isNotEmpty) {
              assignedUserIds.add(data['assignedDriverId'].toString());
            }
            if (data['assignedLibrarianId'] != null &&
                data['assignedLibrarianId'].toString().isNotEmpty) {
              assignedUserIds.add(data['assignedLibrarianId'].toString());
            }

            // Only consider tasks that have been assigned to users and were assigned today
            if (assignedUserIds.isNotEmpty && assignedToday) {
              final status = data['status'] as String? ?? '';
              final completedByUserIds =
                  List<String>.from(data['completedByUserIds'] ?? []);

              // Check if task is pending (not completed by all assigned users)
              bool isCompleted = status.toLowerCase() == 'completed' ||
                  assignedUserIds
                      .every((userId) => completedByUserIds.contains(userId));

              if (!isCompleted) {
                pendingTodayCount++;
              }
            }
          }

          todayPendingCount.value = pendingTodayCount;
        },
        onError: (error) {
          if (kDebugMode) {
            print('Error listening to pending tasks: $error');
            print('DailyTaskNotificationService: Auth state at error: ${FirebaseAuth.instance.currentUser}');
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


  /// Get daily task statistics
  Map<String, int> get dailyStats => {
        'assigned': todayAssignedCount.value, // Tasks assigned today
        'completed': todayCompletedCount.value, // Tasks completed today
        'pending': todayPendingCount
            .value, // Tasks assigned today but not yet completed
      };

  /// Get completion rate as percentage
  double get completionRate {
    if (todayAssignedCount.value == 0) return 0.0;
    return (todayCompletedCount.value / todayAssignedCount.value) * 100;
  }

  /// Check if there are any notifications to show
  bool get hasNotifications =>
      hasNewAssignments.value || hasNewCompletions.value;

  /// Clear notification flags
  void clearNotifications() {
    hasNewAssignments.value = false;
    hasNewCompletions.value = false;
  }

  /// Manually refresh the listeners (useful for timezone changes or day transitions)
  void refreshListeners() {
    _assignedTasksSubscription?.cancel();
    _completedTasksSubscription?.cancel();
    _pendingTasksSubscription?.cancel();
    _previousAssignedCount = 0;
    _initializeListeners();
  }

  /// Get tasks assigned to a specific user today
  Future<List<Task>> getTasksAssignedToUserToday(String userId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final snapshot = await _firestore.collection('tasks').get();

      final tasks = <Task>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final assignedAt = data['assignedAt'];

        // Check if task was assigned today
        bool assignedToday = false;
        if (assignedAt != null) {
          DateTime? assignmentDate;
          if (assignedAt is Timestamp) {
            assignmentDate = assignedAt.toDate();
          } else if (assignedAt is String) {
            assignmentDate = DateTime.tryParse(assignedAt);
          }

          if (assignmentDate != null &&
              assignmentDate.isAfter(startOfDay) &&
              assignmentDate.isBefore(endOfDay.add(Duration(seconds: 1)))) {
            assignedToday = true;
          }
        }

        if (assignedToday) {
          data['taskId'] = doc.id;
          final task = Task.fromMap(data);
          // Check if user is assigned to this task
          if (task.assignedUserIds.contains(userId)) {
            tasks.add(task);
          }
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
          .where('assignmentTimestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
          .where('assignmentTimestamp',
              isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      final weeklyData = <String, Map<String, int>>{};

      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        weeklyData[dateKey] = {'assigned': 0, 'completed': 0};
      }

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final assignmentTimestamp = data['assignmentTimestamp'] as Timestamp?;
        final status = data['status'] as String?;
        final lastModified = data['lastModified'] as Timestamp?;

        if (assignmentTimestamp != null) {
          final assignmentDate = assignmentTimestamp.toDate();
          final dateKey =
              '${assignmentDate.year}-${assignmentDate.month.toString().padLeft(2, '0')}-${assignmentDate.day.toString().padLeft(2, '0')}';

          if (weeklyData.containsKey(dateKey)) {
            weeklyData[dateKey]!['assigned'] =
                (weeklyData[dateKey]!['assigned'] ?? 0) + 1;
          }
        }

        if (status == 'completed' && lastModified != null) {
          final completionDate = lastModified.toDate();
          final dateKey =
              '${completionDate.year}-${completionDate.month.toString().padLeft(2, '0')}-${completionDate.day.toString().padLeft(2, '0')}';

          if (weeklyData.containsKey(dateKey)) {
            weeklyData[dateKey]!['completed'] =
                (weeklyData[dateKey]!['completed'] ?? 0) + 1;
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
