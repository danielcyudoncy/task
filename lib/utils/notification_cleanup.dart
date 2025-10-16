// utils/notification_cleanup.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NotificationCleanup {
  /// Delete all task_assignment notifications that have null or empty taskId
  static Future<void> deleteInvalidTaskAssignmentNotifications() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        debugPrint('NotificationCleanup: No user logged in');
        return;
      }

      debugPrint('NotificationCleanup: Starting cleanup for user $uid');

      // Get all notifications for the current user
      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .get();

      debugPrint(
          'NotificationCleanup: Found ${notificationsSnapshot.docs.length} notifications');

      int deletedCount = 0;

      for (final notifDoc in notificationsSnapshot.docs) {
        final data = notifDoc.data();
        final type = data['type']?.toString();
        final taskId = data['taskId'];

        // Delete task_assignment notifications without valid taskId
        if (type == 'task_assignment' &&
            (taskId == null || taskId.toString().isEmpty)) {
          debugPrint(
              'NotificationCleanup: Deleting invalid notification ${notifDoc.id}');

          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('notifications')
              .doc(notifDoc.id)
              .delete();

          deletedCount++;
        }
      }

      debugPrint(
          'NotificationCleanup: Deleted $deletedCount invalid notifications');
    } catch (e) {
      debugPrint('NotificationCleanup: Error during cleanup: $e');
    }
  }

  /// Create new task_assignment notifications for tasks assigned to the current user
  static Future<void> createMissingTaskAssignmentNotifications() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        debugPrint('NotificationCleanup: No user logged in');
        return;
      }

      debugPrint(
          'NotificationCleanup: Creating missing notifications for user $uid');

      // Find all tasks assigned to this user
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo', isEqualTo: uid)
          .get();

      // Also check other assignment fields
      final reporterTasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedReporterId', isEqualTo: uid)
          .get();

      final cameramanTasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedCameramanId', isEqualTo: uid)
          .get();

      // Combine all assigned tasks
      final allAssignedTasks = <String, Map<String, dynamic>>{};

      for (final doc in tasksSnapshot.docs) {
        allAssignedTasks[doc.id] = doc.data();
      }
      for (final doc in reporterTasksSnapshot.docs) {
        allAssignedTasks[doc.id] = doc.data();
      }
      for (final doc in cameramanTasksSnapshot.docs) {
        allAssignedTasks[doc.id] = doc.data();
      }

      debugPrint(
          'NotificationCleanup: Found ${allAssignedTasks.length} assigned tasks');

      // Get existing notifications to avoid duplicates
      final existingNotificationsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('type', isEqualTo: 'task_assignment')
          .get();

      final existingTaskIds = existingNotificationsSnapshot.docs
          .map((doc) => doc.data()['taskId']?.toString())
          .where((taskId) => taskId != null && taskId.isNotEmpty)
          .toSet();

      debugPrint(
          'NotificationCleanup: Found ${existingTaskIds.length} existing valid notifications');

      int createdCount = 0;

      // Create notifications for tasks that don't have them
      for (final entry in allAssignedTasks.entries) {
        final taskId = entry.key;
        final taskData = entry.value;

        if (!existingTaskIds.contains(taskId)) {
          debugPrint(
              'NotificationCleanup: Creating notification for task $taskId');

          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('notifications')
              .add({
            'type': 'task_assignment',
            'taskId': taskId,
            'title': taskData['title'] ?? 'Task Assignment',
            'message':
                'You have been assigned to a task: ${taskData['description'] ?? 'No description'}',
            'isRead': false,
            'timestamp': FieldValue.serverTimestamp(),
          });

          createdCount++;
        }
      }

      debugPrint(
          'NotificationCleanup: Created $createdCount new notifications');
    } catch (e) {
      debugPrint('NotificationCleanup: Error creating notifications: $e');
    }
  }

  /// Complete cleanup and recreation process
  static Future<void> performCompleteCleanup() async {
    debugPrint('NotificationCleanup: Starting complete cleanup process');

    // Step 1: Delete invalid notifications
    await deleteInvalidTaskAssignmentNotifications();

    // Step 2: Wait a moment for deletions to propagate
    await Future.delayed(const Duration(milliseconds: 1000));

    // Step 3: Create missing notifications
    await createMissingTaskAssignmentNotifications();

    debugPrint('NotificationCleanup: Complete cleanup process finished');
  }
}
