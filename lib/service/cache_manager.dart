// service/cache_manager.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'intelligent_cache_service.dart';
import 'user_cache_service.dart';
// import '../models/task.dart'; // Not needed for this implementation

/// High-level cache manager that coordinates different caching strategies
class CacheManager extends GetxService {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  late final IntelligentCacheService _intelligentCache;
  late final UserCacheService _userCache;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Cache warming status
  final RxBool _isWarming = false.obs;
  final RxDouble _warmingProgress = 0.0.obs;
  
  bool get isWarming => _isWarming.value;
  double get warmingProgress => _warmingProgress.value;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    await initialize();
  }
  
  /// Initialize the cache manager
  Future<void> initialize() async {
    debugPrint('CacheManager: Initializing cache manager');
    
    _intelligentCache = Get.find<IntelligentCacheService>();
    _userCache = Get.find<UserCacheService>();
    
    // Start background cache warming
    _startBackgroundCacheWarming();
    
    debugPrint('CacheManager: Cache manager initialized');
  }
  
  /// Get user data with intelligent caching
  Future<Map<String, dynamic>?> getUserData(String userId, {bool forceRefresh = false}) async {
    return await _intelligentCache.get<Map<String, dynamic>>(
      userId,
      category: CacheCategories.userData,
      forceRefresh: forceRefresh,
      fallback: () async {
        final doc = await _firestore.collection('users').doc(userId).get();
        return doc.exists ? doc.data()! : <String, dynamic>{};
      },
    );
  }
  
  /// Get task data with intelligent caching
  Future<Map<String, dynamic>?> getTaskData(String taskId, {bool forceRefresh = false}) async {
    return await _intelligentCache.get<Map<String, dynamic>>(
      taskId,
      category: CacheCategories.taskData,
      forceRefresh: forceRefresh,
      fallback: () async {
        final doc = await _firestore.collection('tasks').doc(taskId).get();
        return doc.exists ? doc.data()! : <String, dynamic>{};
      },
    );
  }
  
  /// Get tasks list with intelligent caching
  Future<List<Map<String, dynamic>>?> getTasksList({
    String? assignedTo,
    String? status,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'tasks_${assignedTo ?? 'all'}_${status ?? 'all'}';
    
    return await _intelligentCache.get<List<Map<String, dynamic>>>(
      cacheKey,
      category: CacheCategories.taskData,
      forceRefresh: forceRefresh,
      customExpiry: const Duration(minutes: 10), // Shorter expiry for lists
      fallback: () async {
        Query query = _firestore.collection('tasks');
        
        if (assignedTo != null) {
          query = query.where('assignedTo', isEqualTo: assignedTo);
        }
        if (status != null) {
          query = query.where('status', isEqualTo: status);
        }
        
        final snapshot = await query.get();
        return snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        }).toList();
      },
    );
  }
  
  /// Get news data with intelligent caching
  Future<List<Map<String, dynamic>>?> getNewsData(String source, {bool forceRefresh = false}) async {
    return await _intelligentCache.get<List<Map<String, dynamic>>>(
      'news_$source',
      category: CacheCategories.newsData,
      forceRefresh: forceRefresh,
      fallback: () async {
        // This would integrate with your news service
        // For now, return empty list
        return <Map<String, dynamic>>[];
      },
    );
  }
  
  /// Cache user settings
  Future<void> cacheUserSettings(String userId, Map<String, dynamic> settings) async {
    await _intelligentCache.set(
      'settings_$userId',
      settings,
      category: CacheCategories.settings,
    );
  }
  
  /// Get user settings from cache
  Future<Map<String, dynamic>?> getUserSettings(String userId, {bool forceRefresh = false}) async {
    return await _intelligentCache.get<Map<String, dynamic>>(
      'settings_$userId',
      category: CacheCategories.settings,
      forceRefresh: forceRefresh,
    );
  }
  
  /// Cache static data (like app configuration)
  Future<void> cacheStaticData(String key, dynamic data) async {
    await _intelligentCache.set(
      key,
      data,
      category: CacheCategories.staticData,
    );
  }
  
  /// Get static data from cache
  Future<T?> getStaticData<T>(String key, {bool forceRefresh = false}) async {
    return await _intelligentCache.get<T>(
      key,
      category: CacheCategories.staticData,
      forceRefresh: forceRefresh,
    );
  }
  
  /// Cache temporary data (short-lived)
  Future<void> cacheTemporaryData(String key, dynamic data) async {
    await _intelligentCache.set(
      key,
      data,
      category: CacheCategories.temporary,
    );
  }
  
  /// Get temporary data from cache
  Future<T?> getTemporaryData<T>(String key) async {
    return await _intelligentCache.get<T>(
      key,
      category: CacheCategories.temporary,
    );
  }
  
  /// Warm up cache with frequently accessed data
  Future<void> warmUpCache() async {
    if (_isWarming.value) return;
    
    _isWarming.value = true;
    _warmingProgress.value = 0.0;
    
    try {
      debugPrint('CacheManager: Starting cache warm-up');
      
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('CacheManager: No authenticated user for cache warm-up');
        return;
      }
      
      final tasks = <Future>[];
      
      // 1. Warm up current user data
      tasks.add(_warmUpCurrentUser(currentUser.uid));
      _warmingProgress.value = 0.1;
      
      // 2. Warm up user cache
      tasks.add(_warmUpUserCache());
      _warmingProgress.value = 0.3;
      
      // 3. Warm up recent tasks
      tasks.add(_warmUpRecentTasks(currentUser.uid));
      _warmingProgress.value = 0.5;
      
      // 4. Warm up user settings
      tasks.add(_warmUpUserSettings(currentUser.uid));
      _warmingProgress.value = 0.7;
      
      // 5. Warm up static data
      tasks.add(_warmUpStaticData());
      _warmingProgress.value = 0.9;
      
      // Wait for all tasks to complete
      await Future.wait(tasks);
      
      // 6. Preload frequently accessed data
      await _intelligentCache.preloadFrequentData();
      _warmingProgress.value = 1.0;
      
      debugPrint('CacheManager: Cache warm-up completed');
    } catch (e) {
      debugPrint('CacheManager: Error during cache warm-up: $e');
    } finally {
      _isWarming.value = false;
    }
  }
  
  /// Invalidate cache for specific user
  Future<void> invalidateUserCache(String userId) async {
    await _intelligentCache.remove(userId, category: CacheCategories.userData);
    await _intelligentCache.remove('settings_$userId', category: CacheCategories.settings);
    await _userCache.clearUserCache(userId);
    
    debugPrint('CacheManager: Invalidated cache for user $userId');
  }
  
  /// Invalidate cache for specific task
  Future<void> invalidateTaskCache(String taskId) async {
    await _intelligentCache.remove(taskId, category: CacheCategories.taskData);
    
    // Also invalidate related task lists
    await _intelligentCache.clearCategory(CacheCategories.taskData);
    
    debugPrint('CacheManager: Invalidated cache for task $taskId');
  }
  
  /// Invalidate all task-related cache
  Future<void> invalidateAllTaskCache() async {
    await _intelligentCache.clearCategory(CacheCategories.taskData);
    debugPrint('CacheManager: Invalidated all task cache');
  }
  
  /// Invalidate news cache
  Future<void> invalidateNewsCache() async {
    await _intelligentCache.clearCategory(CacheCategories.newsData);
    debugPrint('CacheManager: Invalidated news cache');
  }
  
  /// Get comprehensive cache statistics
  Map<String, dynamic> getCacheStatistics() {
    final intelligentStats = _intelligentCache.getStatistics();
    final userCacheStats = {
      'cached_user_names': _userCache.cachedUserAvatarsCount,
      'has_current_user_data': _userCache.hasCurrentUserData,
      'last_user_data_update': _userCache.lastUserDataUpdate?.toIso8601String(),
      'last_user_names_update': _userCache.lastUserNamesUpdate?.toIso8601String(),
    };
    
    return {
      'intelligent_cache': intelligentStats,
      'user_cache': userCacheStats,
      'cache_warming': {
        'is_warming': _isWarming.value,
        'warming_progress': _warmingProgress.value,
      },
    };
  }
  
  /// Optimize all caches
  Future<void> optimizeAllCaches() async {
    debugPrint('CacheManager: Optimizing all caches');
    
    await Future.wait([
      _intelligentCache.optimizeCache(),
      _userCache.preFetchAllUsers(forceRefresh: false),
    ]);
    
    debugPrint('CacheManager: Cache optimization completed');
  }
  
  /// Clear all caches
  Future<void> clearAllCaches() async {
    debugPrint('CacheManager: Clearing all caches');
    
    await Future.wait([
      _intelligentCache.clearAll(),
      _userCache.clearCache(),
    ]);
    
    debugPrint('CacheManager: All caches cleared');
  }
  
  // Private helper methods
  
  void _startBackgroundCacheWarming() {
    // Warm up cache after a short delay to avoid blocking app startup
    Timer(const Duration(seconds: 5), () {
      warmUpCache();
    });
    
    // Periodic cache optimization
    Timer.periodic(const Duration(hours: 2), (_) {
      optimizeAllCaches();
    });
  }
  
  Future<void> _warmUpCurrentUser(String userId) async {
    try {
      await getUserData(userId);
      debugPrint('CacheManager: Warmed up current user data');
    } catch (e) {
      debugPrint('CacheManager: Error warming up current user data: $e');
    }
  }
  
  Future<void> _warmUpUserCache() async {
    try {
      await _userCache.preFetchAllUsers();
      debugPrint('CacheManager: Warmed up user cache');
    } catch (e) {
      debugPrint('CacheManager: Error warming up user cache: $e');
    }
  }
  
  Future<void> _warmUpRecentTasks(String userId) async {
    try {
      // Get recent tasks assigned to current user
      await getTasksList(assignedTo: userId);
      
      // Get recent tasks created by current user
      final recentTasks = await _firestore
          .collection('tasks')
          .where('createdById', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      
      // Cache individual task data
      for (final doc in recentTasks.docs) {
        await _intelligentCache.set(
          doc.id,
          doc.data(),
          category: CacheCategories.taskData,
        );
      }
      
      debugPrint('CacheManager: Warmed up recent tasks');
    } catch (e) {
      debugPrint('CacheManager: Error warming up recent tasks: $e');
    }
  }
  
  Future<void> _warmUpUserSettings(String userId) async {
    try {
      // This would load user settings from Firestore
      // For now, we'll just create a placeholder
      final settings = {
        'theme': 'system',
        'notifications': true,
        'language': 'en',
      };
      
      await cacheUserSettings(userId, settings);
      debugPrint('CacheManager: Warmed up user settings');
    } catch (e) {
      debugPrint('CacheManager: Error warming up user settings: $e');
    }
  }
  
  Future<void> _warmUpStaticData() async {
    try {
      // Cache static app configuration data
      final staticData = {
        'app_version': '1.0.0',
        'api_endpoints': {
          'news': 'https://api.news.com',
          'weather': 'https://api.weather.com',
        },
        'feature_flags': {
          'new_ui': true,
          'beta_features': false,
        },
      };
      
      await cacheStaticData('app_config', staticData);
      debugPrint('CacheManager: Warmed up static data');
    } catch (e) {
      debugPrint('CacheManager: Error warming up static data: $e');
    }
  }
}

/// Cache warming progress model
class CacheWarmingProgress {
  final bool isWarming;
  final double progress;
  final String? currentTask;
  
  CacheWarmingProgress({
    required this.isWarming,
    required this.progress,
    this.currentTask,
  });
}