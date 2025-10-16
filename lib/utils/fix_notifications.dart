// utils/fix_notifications.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NotificationFixer {
  static Future<void> fixExistingNotifications() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        debugPrint('NotificationFixer: No user logged in');
        return;
      }

      debugPrint(
          'NotificationFixer: Starting to fix notifications for user $uid');

      // Get all notifications for the current user
      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .get();

      debugPrint(
          'NotificationFixer: Found ${notificationsSnapshot.docs.length} notifications');

      for (final notifDoc in notificationsSnapshot.docs) {
        final data = notifDoc.data();
        final type = data['type']?.toString();
        final taskId = data['taskId'];

        debugPrint('NotificationFixer: Processing notification ${notifDoc.id}');
        debugPrint('  Type: $type');
        debugPrint('  Current TaskId: $taskId');
        debugPrint('  Title: ${data['title']}');
        debugPrint('  IsRead: ${data['isRead']}');

        // If it's a task_assignment notification without taskId, try to find and fix it
        if (type == 'task_assignment' &&
            (taskId == null || taskId.toString().isEmpty)) {
          debugPrint(
              'NotificationFixer: Found task_assignment notification without taskId');

          // Look for tasks that might match this notification
          // We'll try to find tasks assigned to this user
          final tasksSnapshot = await FirebaseFirestore.instance
              .collection('tasks')
              .where('assignedTo', isEqualTo: uid)
              .get();

          if (tasksSnapshot.docs.isNotEmpty) {
            // For now, let's just assign the first matching task
            // In a real scenario, you'd want more sophisticated matching
            final firstTask = tasksSnapshot.docs.first;
            final newTaskId = firstTask.id;

            debugPrint(
                'NotificationFixer: Updating notification with taskId: $newTaskId');

            // Update the notification with the taskId
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('notifications')
                .doc(notifDoc.id)
                .update({
              'taskId': newTaskId,
              'isRead': data['isRead'] ?? false, // Ensure isRead field exists
            });

            debugPrint(
                'NotificationFixer: Successfully updated notification ${notifDoc.id}');
          } else {
            debugPrint(
                'NotificationFixer: No matching tasks found for notification ${notifDoc.id}');
          }
        }

        // Also ensure all notifications have the isRead field (not just 'read')
        if (!data.containsKey('isRead') && data.containsKey('read')) {
          debugPrint(
              'NotificationFixer: Converting read field to isRead for notification ${notifDoc.id}');
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('notifications')
              .doc(notifDoc.id)
              .update({
            'isRead': data['read'] ?? false,
          });
        }
      }

      debugPrint('NotificationFixer: Finished fixing notifications');
    } catch (e) {
      debugPrint('NotificationFixer: Error fixing notifications: $e');
    }
  }

  static Future<void> debugCurrentNotifications() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        debugPrint('NotificationFixer: No user logged in');
        return;
      }

      debugPrint('\n=== DEBUG: Current Notifications for user $uid ===');

      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .get();

      debugPrint('Total notifications: ${notificationsSnapshot.docs.length}');

      for (int i = 0; i < notificationsSnapshot.docs.length; i++) {
        final notifDoc = notificationsSnapshot.docs[i];
        final data = notifDoc.data();

        debugPrint('\nNotification ${i + 1}:');
        debugPrint('  ID: ${notifDoc.id}');
        debugPrint('  Type: ${data['type']}');
        debugPrint('  TaskId: ${data['taskId']}');
        debugPrint('  Title: ${data['title']}');
        debugPrint('  IsRead: ${data['isRead']}');
        debugPrint('  Read (old): ${data['read']}');
        debugPrint('  Message: ${data['message']}');
        debugPrint('  Timestamp: ${data['timestamp']}');
      }

      debugPrint('\n=== END DEBUG ===\n');
    } catch (e) {
      debugPrint('NotificationFixer: Error debugging notifications: $e');
    }
  }
}
