// service/cached_task_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cache_manager.dart';
import 'intelligent_cache_service.dart';

/// Task service with intelligent caching capabilities
class CachedTaskService extends GetxService {
  static final CachedTaskService _instance = CachedTaskService._internal();
  factory CachedTaskService() => _instance;
  CachedTaskService._internal();

  late final CacheManager _cacheManager;
  late final IntelligentCacheService _intelligentCache;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Stream controllers for real-time updates
  final StreamController<List<Map<String, dynamic>>> _tasksStreamController = 
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<Map<String, dynamic>> _taskUpdateController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<List<Map<String, dynamic>>> get tasksStream => _tasksStreamController.stream;
  Stream<Map<String, dynamic>> get taskUpdateStream => _taskUpdateController.stream;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    await initialize();
  }
  
  @override
  void onClose() {
    _tasksStreamController.close();
    _taskUpdateController.close();
    super.onClose();
  }
  
  /// Initialize the cached task service
  Future<void> initialize() async {
    debugPrint('CachedTaskService: Initializing cached task service');
    
    _cacheManager = Get.find<CacheManager>();
    _intelligentCache = Get.find<IntelligentCacheService>();
    
    debugPrint('CachedTaskService: Cached task service initialized');
  }
  
  /// Get task by ID with intelligent caching
  Future<Map<String, dynamic>?> getTask(String taskId, {bool forceRefresh = false}) async {
    try {
      final taskData = await _cacheManager.getTaskData(taskId, forceRefresh: forceRefresh);
      
      if (taskData != null && taskData.isNotEmpty) {
        // Enhance task data with cached user information
        await _enhanceTaskWithUserData(taskData);
        return taskData;
      }
      
      return null;
    } catch (e) {
      debugPrint('CachedTaskService: Error getting task $taskId: $e');
      return null;
    }
  }
  
  /// Get tasks list with intelligent caching and real-time updates
  Future<List<Map<String, dynamic>>> getTasks({
    String? assignedTo,
    String? status,
    String? category,
    bool forceRefresh = false,
    bool enableRealTime = true,
  }) async {
    try {
      // Build cache key based on filters
      final filters = <String>[
        if (assignedTo != null) 'assigned_$assignedTo',
        if (status != null) 'status_$status',
        if (category != null) 'category_$category',
      ];
      final cacheKey = 'tasks_list_${filters.join('_')}';
      
      // Try to get from cache first
      List<Map<String, dynamic>>? cachedTasks;
      if (!forceRefresh) {
        cachedTasks = await _intelligentCache.get<List<Map<String, dynamic>>>(
          cacheKey,
          category: CacheCategories.taskData,
          customExpiry: const Duration(minutes: 5), // Short expiry for lists
        );
      }
      
      // If we have cached data and real-time is disabled, return it
      if (cachedTasks != null && !enableRealTime) {
        await _enhanceTasksWithUserData(cachedTasks);
        return cachedTasks;
      }
      
      // Fetch fresh data from Firestore
      Query query = _firestore.collection('tasks');
      
      if (assignedTo != null) {
        query = query.where('assignedTo', arrayContains: assignedTo);
      }
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      
      query = query.orderBy('createdAt', descending: true).limit(50);
      
      final snapshot = await query.get();
      final tasks = snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
      
      // Cache the results
      await _intelligentCache.set(
        cacheKey,
        tasks,
        category: CacheCategories.taskData,
        customExpiry: const Duration(minutes: 5),
      );
      
      // Enhance with user data
      await _enhanceTasksWithUserData(tasks);
      
      // Emit to stream if real-time is enabled
      if (enableRealTime) {
        _tasksStreamController.add(tasks);
      }
      
      return tasks;
    } catch (e) {
      debugPrint('CachedTaskService: Error getting tasks: $e');
      return [];
    }
  }
  
  /// Get user's assigned tasks with caching
  Future<List<Map<String, dynamic>>> getUserTasks(String userId, {bool forceRefresh = false}) async {
    return await getTasks(
      assignedTo: userId,
      forceRefresh: forceRefresh,
    );
  }
  
  /// Get tasks by status with caching
  Future<List<Map<String, dynamic>>> getTasksByStatus(String status, {bool forceRefresh = false}) async {
    return await getTasks(
      status: status,
      forceRefresh: forceRefresh,
    );
  }
  
  /// Create new task and update cache
  Future<String?> createTask(Map<String, dynamic> taskData) async {
    try {
      // Add metadata
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      taskData.addAll({
        'createdById': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': taskData['status'] ?? 'pending',
      });
      
      // Create task in Firestore
      final docRef = await _firestore.collection('tasks').add(taskData);
      
      // Invalidate related caches
      await _cacheManager.invalidateAllTaskCache();
      
      // Cache the new task
      final newTaskData = {
        'id': docRef.id,
        ...taskData,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      await _intelligentCache.set(
        docRef.id,
        newTaskData,
        category: CacheCategories.taskData,
      );
      
      // Emit update
      _taskUpdateController.add({
        'action': 'created',
        'taskId': docRef.id,
        'taskData': newTaskData,
      });
      
      debugPrint('CachedTaskService: Created task ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('CachedTaskService: Error creating task: $e');
      return null;
    }
  }
  
  /// Update task and refresh cache
  Future<bool> updateTask(String taskId, Map<String, dynamic> updates) async {
    try {
      // Add update metadata
      updates['updatedAt'] = FieldValue.serverTimestamp();
      
      // Update in Firestore
      await _firestore.collection('tasks').doc(taskId).update(updates);
      
      // Invalidate task cache
      await _cacheManager.invalidateTaskCache(taskId);
      
      // Get fresh task data and cache it
      final freshTaskData = await getTask(taskId, forceRefresh: true);
      
      // Emit update
      _taskUpdateController.add({
        'action': 'updated',
        'taskId': taskId,
        'updates': updates,
        'taskData': freshTaskData,
      });
      
      debugPrint('CachedTaskService: Updated task $taskId');
      return true;
    } catch (e) {
      debugPrint('CachedTaskService: Error updating task $taskId: $e');
      return false;
    }
  }
  
  /// Delete task and update cache
  Future<bool> deleteTask(String taskId) async {
    try {
      // Delete from Firestore
      await _firestore.collection('tasks').doc(taskId).delete();
      
      // Remove from cache
      await _cacheManager.invalidateTaskCache(taskId);
      
      // Emit update
      _taskUpdateController.add({
        'action': 'deleted',
        'taskId': taskId,
      });
      
      debugPrint('CachedTaskService: Deleted task $taskId');
      return true;
    } catch (e) {
      debugPrint('CachedTaskService: Error deleting task $taskId: $e');
      return false;
    }
  }
  
  /// Archive task with caching
  Future<bool> archiveTask(String taskId, {
    String? reason,
    String? location,
  }) async {
    final updates = {
      'archived': true,
      'archivedAt': FieldValue.serverTimestamp(),
      'archivedBy': _auth.currentUser?.uid,
      'status': 'archived',
    };
    
    if (reason != null) updates['archiveReason'] = reason;
    if (location != null) updates['archiveLocation'] = location;
    
    return await updateTask(taskId, updates);
  }
  
  /// Unarchive task with caching
  Future<bool> unarchiveTask(String taskId) async {
    final updates = {
      'archived': false,
      'archivedAt': FieldValue.delete(),
      'archivedBy': FieldValue.delete(),
      'archiveReason': FieldValue.delete(),
      'archiveLocation': FieldValue.delete(),
      'status': 'pending',
    };
    
    return await updateTask(taskId, updates);
  }
  
  /// Get task statistics with caching
  Future<Map<String, dynamic>> getTaskStatistics({bool forceRefresh = false}) async {
    return await _intelligentCache.get<Map<String, dynamic>>(
      'task_statistics',
      category: CacheCategories.taskData,
      forceRefresh: forceRefresh,
      customExpiry: const Duration(minutes: 15),
      fallback: () async {
        final tasksSnapshot = await _firestore.collection('tasks').get();
        final tasks = tasksSnapshot.docs;
        
        final stats = {
          'total': tasks.length,
          'pending': tasks.where((doc) => doc.data()['status'] == 'pending').length,
          'in_progress': tasks.where((doc) => doc.data()['status'] == 'in_progress').length,
          'completed': tasks.where((doc) => doc.data()['status'] == 'completed').length,
          'archived': tasks.where((doc) => doc.data()['archived'] == true).length,
          'overdue': tasks.where((doc) {
            final dueDate = doc.data()['dueDate'];
            if (dueDate == null) return false;
            final due = (dueDate as Timestamp).toDate();
            return due.isBefore(DateTime.now()) && doc.data()['status'] != 'completed';
          }).length,
        };
        
        return stats;
      },
    ) ?? {};
  }
  
  /// Search tasks with caching
  Future<List<Map<String, dynamic>>> searchTasks(String query, {bool forceRefresh = false}) async {
    if (query.trim().isEmpty) return [];
    
    final cacheKey = 'search_${query.toLowerCase().replaceAll(' ', '_')}';
    
    return await _intelligentCache.get<List<Map<String, dynamic>>>(
      cacheKey,
      category: CacheCategories.taskData,
      forceRefresh: forceRefresh,
      customExpiry: const Duration(minutes: 10),
      fallback: () async {
        // Simple text search - in production, you might use Algolia or similar
        final tasksSnapshot = await _firestore.collection('tasks')
            .orderBy('createdAt', descending: true)
            .limit(100)
            .get();
        
        final searchResults = <Map<String, dynamic>>[];
        final lowerQuery = query.toLowerCase();
        
        for (final doc in tasksSnapshot.docs) {
          final data = doc.data();
          final title = (data['title'] ?? '').toString().toLowerCase();
          final description = (data['description'] ?? '').toString().toLowerCase();
          
          if (title.contains(lowerQuery) || description.contains(lowerQuery)) {
            searchResults.add({
              'id': doc.id,
              ...data,
            });
          }
        }
        
        return searchResults;
      },
    ) ?? [];
  }
  
  /// Preload user's important tasks
  Future<void> preloadUserTasks(String userId) async {
    try {
      debugPrint('CachedTaskService: Preloading tasks for user $userId');
      
      // Preload assigned tasks
      await getUserTasks(userId);
      
      // Preload recent tasks
      await getTasks(forceRefresh: false);
      
      // Preload task statistics
      await getTaskStatistics();
      
      debugPrint('CachedTaskService: Preloaded tasks for user $userId');
    } catch (e) {
      debugPrint('CachedTaskService: Error preloading user tasks: $e');
    }
  }
  
  /// Clear all task-related caches
  Future<void> clearTaskCaches() async {
    await _cacheManager.invalidateAllTaskCache();
    debugPrint('CachedTaskService: Cleared all task caches');
  }
  
  // Private helper methods
  
  /// Enhance task data with cached user information
  Future<void> _enhanceTaskWithUserData(Map<String, dynamic> taskData) async {
    try {
      // Get creator information
      final creatorId = taskData['createdById'];
      if (creatorId != null) {
        final creatorData = await _cacheManager.getUserData(creatorId);
        if (creatorData != null) {
          taskData['creatorName'] = creatorData['fullName'] ?? 'Unknown';
          taskData['creatorAvatar'] = creatorData['photoUrl'] ?? '';
        }
      }
      
      // Get assignee information
      final assignedTo = taskData['assignedTo'];
      if (assignedTo is List) {
        final assigneeData = <Map<String, dynamic>>[];
        for (final userId in assignedTo) {
          final userData = await _cacheManager.getUserData(userId);
          if (userData != null) {
            assigneeData.add({
              'id': userId,
              'name': userData['fullName'] ?? 'Unknown',
              'avatar': userData['photoUrl'] ?? '',
            });
          }
        }
        taskData['assigneeData'] = assigneeData;
      }
    } catch (e) {
      debugPrint('CachedTaskService: Error enhancing task with user data: $e');
    }
  }
  
  /// Enhance multiple tasks with cached user information
  Future<void> _enhanceTasksWithUserData(List<Map<String, dynamic>> tasks) async {
    await Future.wait(
      tasks.map((task) => _enhanceTaskWithUserData(task)),
    );
  }
}