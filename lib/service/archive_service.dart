// service/archive_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/models/task.dart';
import 'package:task/models/task_metadata.dart';
import 'package:task/service/task_service.dart';

class ArchiveService extends GetxService {
  static ArchiveService get to => Get.find();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final TaskService _taskService;
  bool _isInitialized = false;

  ArchiveService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    TaskService? taskService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _taskService = taskService ?? Get.find<TaskService>();

  /// Initializes the ArchiveService
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize any dependencies here

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize ArchiveService: $e');
    }
  }

  /// Archives a task with the given [taskId], optional [reason], and [location].
  /// Throws a [FirebaseException] if there's an issue with Firestore operations.
  /// Throws an [Exception] if user is not authenticated or task is not found.
  Future<void> archiveTask({
    required String taskId,
    String? reason,
    String? location,
  }) async {
    if (taskId.isEmpty) {
      throw ArgumentError('Task ID cannot be empty');
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final now = DateTime.now();
    final userName = user.displayName ?? 'Unknown User';

    try {
      // First check if task exists
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (!taskDoc.exists) {
        throw Exception('Task not found');
      }

      // Update task in Firestore using transaction for consistency
      await _firestore.runTransaction((transaction) async {
        final taskRef = _firestore.collection('tasks').doc(taskId);
        final taskDoc = await transaction.get(taskRef);

        if (!taskDoc.exists) {
          throw Exception('Task not found');
        }

        transaction.update(taskRef, {
          'status': 'Archived',
          'archivedAt': now,
          'archivedBy': userName,
          'archiveReason': reason,
          'archiveLocation': location,
          'lastModified': now,
          'syncStatus': 'pending',
        });

        // Also update local database
        final updatedTask = Task.fromMap({
          ...taskDoc.data() as Map<String, dynamic>,
          'taskId': taskId,
          'status': 'Archived',
          'archivedAt': now,
          'archivedBy': userName,
          'archiveReason': reason,
          'archiveLocation': location,
          'lastModified': now,
          'syncStatus': 'pending',
        });

        await _taskService.updateTask(updatedTask);
      });

      if (Get.isSnackbarOpen != true) {
        Get.snackbar(
          'Success',
          'Task has been archived successfully',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } on FirebaseException catch (e) {
      debugPrint('Firebase error archiving task: $e');
      rethrow;
    } catch (e) {
      debugPrint('Error archiving task: $e');
      rethrow;
    }
  }

  // Unarchive a task
  Future<void> unarchiveTask(String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Update task in Firestore
      await _firestore.collection('tasks').doc(taskId).update({
        'status': 'Completed',
        'archivedAt': null,
        'archivedBy': null,
        'archiveReason': null,
        'archiveLocation': null,
        'lastModified': DateTime.now(),
        'syncStatus': 'pending',
      });

      // Update local database
      final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
      if (taskDoc.exists) {
        final taskData = Map<String, dynamic>.from(taskDoc.data()!);
        taskData['taskId'] = taskId;

        // Create updated task with unarchived metadata
        final originalTask = Task.fromMap(taskData);
        final updatedTask = originalTask.copyWith(
          core: originalTask.core.copyWith(status: 'Completed'),
          metadata: originalTask.metadata?.copyWith(
            archivedAt: null,
            archivedBy: null,
            archiveReason: null,
            archiveLocation: null,
            lastModified: DateTime.now(),
            syncStatus: 'pending',
          ) ?? TaskMetadata(
            archivedAt: null,
            archivedBy: null,
            archiveReason: null,
            archiveLocation: null,
            lastModified: DateTime.now(),
            syncStatus: 'pending',
          ),
        );

        await _taskService.updateTask(updatedTask);
      }

      Get.snackbar(
        'Success',
        'Task has been unarchived',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('Error unarchiving task: $e');
      rethrow;
    }
  }

  // Get archive statistics
  Future<Map<String, int>> getArchiveStats() async {
    try {
      final snapshot = await _firestore.collection('tasks').get();
      final tasks = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['taskId'] = doc.id;
        return Task.fromMap(data);
      }).toList();

      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, now.day);

      final totalArchived = tasks.where((task) => task.isArchived).length;
      final archivedThisMonth = tasks
          .where((task) =>
              task.isArchived &&
              task.archivedAt != null &&
              task.archivedAt!.isAfter(lastMonth))
          .length;

      return {
        'totalArchived': totalArchived,
        'archivedThisMonth': archivedThisMonth,
      };
    } catch (e) {
      debugPrint('Error getting archive stats: $e');
      return {'totalArchived': 0, 'archivedThisMonth': 0};
    }
  }

  // Get tasks that are due for archiving (completed but not archived)
  Future<List<Task>> getTasksDueForArchiving() async {
    try {
      final snapshot = await _firestore
          .collection('tasks')
          .where('status', isEqualTo: 'Completed')
          .where('archivedAt', isNull: true)
          .orderBy('lastModified', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['taskId'] = doc.id;
        return Task.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error getting tasks due for archiving: $e');
      return [];
    }
  }

  // Bulk archive tasks
  Future<void> bulkArchiveTasks(List<String> taskIds,
      {String? reason, String? location}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final batch = _firestore.batch();
      final now = DateTime.now();
      final userName = user.displayName ?? 'Unknown User';

      for (final taskId in taskIds) {
        final taskRef = _firestore.collection('tasks').doc(taskId);
        batch.update(taskRef, {
          'status': 'Archived',
          'archivedAt': now,
          'archivedBy': userName,
          'archiveReason': reason,
          'archiveLocation': location,
          'lastModified': now,
          'syncStatus': 'pending',
        });
      }

      await batch.commit();

      // Update local database
      final tasks = await _firestore
          .collection('tasks')
          .where(FieldPath.documentId, whereIn: taskIds)
          .get();

      for (final doc in tasks.docs) {
        final data = doc.data();
        data['taskId'] = doc.id;
        final task = Task.fromMap(data);

        // Ensure the task has proper metadata with archive information
        final updatedTask = task.copyWith(
          metadata: task.metadata?.copyWith(
            lastModified: DateTime.now(),
            syncStatus: 'pending',
          ) ?? TaskMetadata(
            lastModified: DateTime.now(),
            syncStatus: 'pending',
          ),
        );

        await _taskService.updateTask(updatedTask);
      }

      Get.snackbar(
        'Success',
        '${taskIds.length} tasks have been archived',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('Error bulk archiving tasks: $e');
      rethrow;
    }
  }

  // Show archive dialog with options
  Future<void> showArchiveDialog(BuildContext context, String taskId) async {
    final reasonController = TextEditingController();
    final locationController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Archive Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Please provide a reason for archiving this task:'),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason for archiving',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('Location (optional):'),
                const SizedBox(height: 8),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Physical/Digital location',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Shelf A-12, Cloud Storage, etc.',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please provide a reason for archiving')),
                  );
                  return;
                }

                Navigator.of(context).pop();

                try {
                  await archiveTask(
                    taskId: taskId,
                    reason: reasonController.text.trim(),
                    location: locationController.text.trim().isNotEmpty
                        ? locationController.text.trim()
                        : null,
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error archiving task: $e')),
                    );
                  }
                }
              },
              child: const Text('Archive'),
            ),
          ],
        );
      },
    );
  }
}
