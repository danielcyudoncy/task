// controllers/notification_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/utils/snackbar_utils.dart';

class NotificationController extends GetxController {
  final RxList<Map<String, dynamic>> notifications =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> validNotifications =
      <Map<String, dynamic>>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxInt validUnreadCount = 0.obs;
  final RxInt taskAssignmentUnreadCount = 0.obs;
  final RxInt totalNotifications = 0.obs;
  final RxBool isLoading = false.obs;

  // Safe snackbar method
  void _safeSnackbar(String title, String message) {
    SnackbarUtils.showSnackbar(title, message);
  }

  @override
  void onInit() {
    super.onInit();
    // Delay notification fetching to ensure proper initialization
    Future.delayed(const Duration(milliseconds: 200), () {
      if (Get.isRegistered<NotificationController>()) {
        // Only fetch notifications if user is authenticated
        if (FirebaseAuth.instance.currentUser != null) {
          fetchNotifications();
        } else {
          debugPrint('NotificationController: User not authenticated, skipping notification fetch');
        }
      }
    });
  }

  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        debugPrint('NotificationController: No user ID available');
        return;
      }

      final stream = FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("notifications")
          .orderBy("timestamp", descending: true)
          .snapshots()
          .handleError((error) {
        debugPrint("Notification Stream Error: $error");
        return const Stream.empty();
      });

      notifications.bindStream(
        stream.asyncMap((snapshot) async {
          try {
            final docs = snapshot.docs;
            totalNotifications.value = docs.length;

            final parsedNotifications = docs.map((doc) {
              try {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                final notification = {
                  'id': doc.id,
                  'title': data['title']?.toString() ?? 'No Title',
                  'message': data['message']?.toString() ?? 'No Message',
                  'timestamp': data['timestamp'] as Timestamp?,
                  'isRead': data['isRead'] as bool? ?? false,
                  'type': data['type']?.toString(),
                  'taskId': data['taskId'],
                };
                debugPrint('Parsed notification: ${notification['type']} - ${notification['taskId']}');
                return notification;
              } catch (e) {
                debugPrint('Error parsing notification  [${doc.id}]: $e');
                return {
                  'id': doc.id,
                  'title': 'Invalid Notification',
                  'message': 'Could not load this notification',
                  'timestamp': Timestamp.now(),
                  'isRead': true,
                };
              }
            }).toList();

            debugPrint('About to call _updateValidNotifications with ${parsedNotifications.length} notifications');
            await _updateValidNotifications(parsedNotifications);
            debugPrint('Finished _updateValidNotifications call');
            updateUnreadCount(parsedNotifications);
            return parsedNotifications;
          } catch (e) {
            debugPrint('Error processing notification stream: $e');
            return <Map<String, dynamic>>[];
          }
        }),
      );
    } catch (e) {
      debugPrint('Fetch Notifications Error: $e');
      _safeSnackbar('Error', 'Failed to setup notifications stream');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _updateValidNotifications(List<Map<String, dynamic>> notificationsList) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      validNotifications.value = [];
      validUnreadCount.value = 0;
      return;
    }
    
    debugPrint('_updateValidNotifications: Processing ${notificationsList.length} notifications for user $uid');
    
    List<Map<String, dynamic>> valid = [];
    for (final n in notificationsList) {
      final type = n['type']?.toString();
      debugPrint('_updateValidNotifications: Notification type: $type');
      
      if (type == 'task_assigned' || type == 'task_assignment') {
        final taskId = n['taskId']?.toString();
        debugPrint('_updateValidNotifications: Task ID: $taskId');
        
        if (taskId != null && taskId.isNotEmpty) {
          final taskDoc = await FirebaseFirestore.instance.collection('tasks').doc(taskId).get();
          if (taskDoc.exists) {
            final data = taskDoc.data() as Map<String, dynamic>;
            debugPrint('_updateValidNotifications: Task data keys: ${data.keys.toList()}');
            debugPrint('_updateValidNotifications: assignedReporterId: ${data['assignedReporterId']}');
            debugPrint('_updateValidNotifications: assignedCameramanId: ${data['assignedCameramanId']}');
            debugPrint('_updateValidNotifications: assignedTo: ${data['assignedTo']}');
            debugPrint('_updateValidNotifications: Current user ID: $uid');
            
            if (data['assignedReporterId'] == uid || data['assignedCameramanId'] == uid || data['assignedDriverId'] == uid || data['assignedLibrarianId'] == uid || data['assignedTo'] == uid) {
              debugPrint('_updateValidNotifications: Task assignment matches! Adding notification');
              valid.add(n);
            } else {
              debugPrint('_updateValidNotifications: Task assignment does not match');
            }
          } else {
            debugPrint('_updateValidNotifications: Task document does not exist');
          }
        } else {
          debugPrint('_updateValidNotifications: Task ID is null or empty');
        }
      } else if (type == 'task_approved' || type == 'task_rejected') {
        // For approval notifications, we don't need to validate against a task
        // since they are sent directly to the task creator
        debugPrint('_updateValidNotifications: Task approval/rejection notification, adding directly');
        valid.add(n);
      } else {
        debugPrint('_updateValidNotifications: Non-task notification, adding directly');
        valid.add(n);
      }
    }
    
    debugPrint('_updateValidNotifications: Final valid notifications: ${valid.length}');
    validNotifications.value = valid;
    validUnreadCount.value = valid.where((n) => !(n['isRead'] as bool? ?? true)).length;
    
    // Calculate task assignment unread count specifically
    final taskAssignmentNotifications = valid.where((n) {
      final type = n['type']?.toString();
      return type == 'task_assigned' || type == 'task_assignment';
    }).toList();
    taskAssignmentUnreadCount.value = taskAssignmentNotifications.where((n) => !(n['isRead'] as bool? ?? true)).length;
    debugPrint('_updateValidNotifications: Task assignment unread count: ${taskAssignmentUnreadCount.value}');
  }

  void updateUnreadCount(List<Map<String, dynamic>>? currentNotifications) {
    try {
      final notificationsList = currentNotifications ?? notifications;
      unreadCount.value = notificationsList.where((n) {
        final isRead = n['isRead'] as bool? ?? true;
        return !isRead;
      }).length;
    } catch (e) {
      debugPrint('Update Unread Count Error: $e');
      unreadCount.value = 0;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      // Update local state immediately
      final index = notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        notifications[index]['isRead'] = true;
        updateUnreadCount(notifications);
        // Recalculate task assignment unread count
        await _updateValidNotifications(notifications);
      }
    } catch (e) {
      debugPrint('Mark as Read Error: $e');
      _safeSnackbar('Error', 'Failed to mark notification as read');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final batch = FirebaseFirestore.instance.batch();
      final collectionRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications');

      final unreadNotifications =
          notifications.where((n) => !(n['isRead'] as bool)).toList();

      for (final notification in unreadNotifications) {
        batch.update(
          collectionRef.doc(notification['id']),
          {'isRead': true},
        );
      }

      await batch.commit();

      // Update local state
      for (final notification in notifications) {
        notification['isRead'] = true;
      }
      unreadCount.value = 0;
      taskAssignmentUnreadCount.value = 0;
    } catch (e) {
      debugPrint('Mark All as Read Error: $e');
      _safeSnackbar('Error', 'Failed to mark all notifications as read');
    }
  }

  // Add this method to your NotificationController class
  Future<void> deleteNotification(String notificationId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // Remove from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      // Remove from local state
      notifications.removeWhere((n) => n['id'] == notificationId);
      validNotifications.removeWhere((n) => n['id'] == notificationId);

      // Update counts
      totalNotifications.value = notifications.length;
      updateUnreadCount(notifications);
      validUnreadCount.value = validNotifications.where((n) => !(n['isRead'] as bool? ?? true)).length;

      _safeSnackbar('Success', 'Notification deleted');
    } catch (e) {
      debugPrint('Delete Notification Error: $e');
      _safeSnackbar('Error', 'Failed to delete notification');
    }
  }
}
