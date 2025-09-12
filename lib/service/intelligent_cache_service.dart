// service/intelligent_cache_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';

/// Intelligent caching service with advanced features
class IntelligentCacheService extends GetxService {
  static final IntelligentCacheService _instance = IntelligentCacheService._internal();
  factory IntelligentCacheService() => _instance;
  IntelligentCacheService._internal();

  // Cache configuration
  static const String _cachePrefix = 'intelligent_cache_';
  static const String _metadataKey = 'cache_metadata';
  static const String _accessLogKey = 'cache_access_log';

  
  // Cache expiry configurations
  static const Map<String, Duration> _cacheExpiryTimes = {
    'user_data': Duration(hours: 6),
    'task_data': Duration(hours: 2),
    'news_data': Duration(minutes: 30),
    'settings': Duration(days: 7),
    'static_data': Duration(days: 1),
    'temporary': Duration(minutes: 15),
  };
  
  // Memory cache limits
  static const int _maxCacheEntries = 1000;
  
  // In-memory cache for frequently accessed data
  final Map<String, CacheEntry> _memoryCache = {};
  final Map<String, DateTime> _accessLog = {};
  final Map<String, int> _accessCount = {};
  
  // Cache statistics
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _cacheEvictions = 0;
  
  SharedPreferences? _prefs;
  Timer? _cleanupTimer;
  Timer? _compressionTimer;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    await initialize();
  }
  
  @override
  void onClose() {
    _cleanupTimer?.cancel();
    _compressionTimer?.cancel();
    super.onClose();
  }
  
  /// Initialize the intelligent cache service
  Future<void> initialize() async {
    debugPrint('IntelligentCacheService: Initializing intelligent cache service');
    
    _prefs = await SharedPreferences.getInstance();
    await _loadCacheMetadata();
    await _loadAccessLog();
    
    // Start periodic cleanup and compression
    _startPeriodicTasks();
    
    debugPrint('IntelligentCacheService: Intelligent cache service initialized');
  }
  
  /// Get data from cache with intelligent fallback
  Future<T?> get<T>(String key, {
    String category = 'default',
    Future<T> Function()? fallback,
    bool forceRefresh = false,
    Duration? customExpiry,
  }) async {
    final cacheKey = _buildCacheKey(category, key);
    
    // Record access
    _recordAccess(cacheKey);
    
    // Check memory cache first
    if (!forceRefresh && _memoryCache.containsKey(cacheKey)) {
      final entry = _memoryCache[cacheKey]!;
      if (_isEntryValid(entry, customExpiry)) {
        _cacheHits++;
        debugPrint('IntelligentCacheService: Memory cache hit for $cacheKey');
        return _deserializeData<T>(entry.data);
      } else {
        _memoryCache.remove(cacheKey);
      }
    }
    
    // Check persistent cache
    if (!forceRefresh) {
      final cachedData = await _getPersistentCache(cacheKey, customExpiry);
      if (cachedData != null) {
        _cacheHits++;
        // Store in memory cache for faster future access
        _storeInMemoryCache(cacheKey, cachedData, category);
        debugPrint('IntelligentCacheService: Persistent cache hit for $cacheKey');
        return _deserializeData<T>(cachedData);
      }
    }
    
    // Cache miss - use fallback if provided
    _cacheMisses++;
    if (fallback != null) {
      try {
        final data = await fallback();
        if (data != null) {
          await set(key, data, category: category, customExpiry: customExpiry);
        }
        return data;
      } catch (e) {
        debugPrint('IntelligentCacheService: Fallback failed for $cacheKey: $e');
      }
    }
    
    return null;
  }
  
  /// Store data in cache with intelligent compression
  Future<void> set<T>(String key, T data, {
    String category = 'default',
    Duration? customExpiry,
    bool compress = false,
  }) async {
    final cacheKey = _buildCacheKey(category, key);
    final serializedData = _serializeData(data);
    final expiry = customExpiry ?? _cacheExpiryTimes[category] ?? const Duration(hours: 1);
    
    // Store in memory cache
    _storeInMemoryCache(cacheKey, serializedData, category);
    
    // Store in persistent cache
    await _setPersistentCache(cacheKey, serializedData, expiry, compress);
    
    debugPrint('IntelligentCacheService: Cached data for $cacheKey (expires in ${expiry.inMinutes} minutes)');
  }
  
  /// Remove specific cache entry
  Future<void> remove(String key, {String category = 'default'}) async {
    final cacheKey = _buildCacheKey(category, key);
    
    // Remove from memory cache
    _memoryCache.remove(cacheKey);
    
    // Remove from persistent cache
    await _prefs?.remove(cacheKey);
    await _prefs?.remove('${cacheKey}_metadata');
    
    debugPrint('IntelligentCacheService: Removed cache entry for $cacheKey');
  }
  
  /// Clear cache by category
  Future<void> clearCategory(String category) async {
    final prefix = _buildCacheKey(category, '');
    
    // Clear from memory cache
    _memoryCache.removeWhere((key, value) => key.startsWith(prefix));
    
    // Clear from persistent cache
    final keys = _prefs?.getKeys().where((key) => key.startsWith(prefix)).toList() ?? [];
    for (final key in keys) {
      await _prefs?.remove(key);
    }
    
    debugPrint('IntelligentCacheService: Cleared cache category: $category');
  }
  
  /// Clear all cache data
  Future<void> clearAll() async {
    debugPrint('IntelligentCacheService: Clearing all cache data');
    
    // Clear memory cache
    _memoryCache.clear();
    _accessLog.clear();
    _accessCount.clear();
    
    // Clear persistent cache
    final keys = _prefs?.getKeys().where((key) => key.startsWith(_cachePrefix)).toList() ?? [];
    for (final key in keys) {
      await _prefs?.remove(key);
    }
    
    // Reset statistics
    _cacheHits = 0;
    _cacheMisses = 0;
    _cacheEvictions = 0;
  }
  
  /// Get cache statistics
  Map<String, dynamic> getStatistics() {
    final totalRequests = _cacheHits + _cacheMisses;
    final hitRate = totalRequests > 0 ? (_cacheHits / totalRequests * 100) : 0.0;
    
    return {
      'cache_hits': _cacheHits,
      'cache_misses': _cacheMisses,
      'cache_evictions': _cacheEvictions,
      'hit_rate': hitRate.toStringAsFixed(2),
      'memory_cache_size': _memoryCache.length,
      'most_accessed_keys': _getMostAccessedKeys(),
      'cache_size_mb': _estimateCacheSize(),
    };
  }
  
  /// Preload frequently accessed data
  Future<void> preloadFrequentData() async {
    debugPrint('IntelligentCacheService: Preloading frequently accessed data');
    
    final mostAccessed = _getMostAccessedKeys();
    for (final key in mostAccessed.take(10)) {
      if (!_memoryCache.containsKey(key)) {
        final data = await _getPersistentCache(key, null);
        if (data != null) {
          final category = _extractCategoryFromKey(key);
          _storeInMemoryCache(key, data, category);
        }
      }
    }
  }
  
  /// Optimize cache performance
  Future<void> optimizeCache() async {
    debugPrint('IntelligentCacheService: Optimizing cache performance');
    
    // Remove expired entries
    await _cleanupExpiredEntries();
    
    // Compress large entries
    await _compressLargeEntries();
    
    // Evict least recently used entries if memory is full
    await _evictLRUEntries();
    
    debugPrint('IntelligentCacheService: Cache optimization completed');
  }
  
  // Private helper methods
  
  String _buildCacheKey(String category, String key) {
    return '$_cachePrefix${category}_$key';
  }
  
  void _recordAccess(String key) {
    _accessLog[key] = DateTime.now();
    _accessCount[key] = (_accessCount[key] ?? 0) + 1;
  }
  
  bool _isEntryValid(CacheEntry entry, Duration? customExpiry) {
    final expiry = customExpiry ?? entry.expiry;
    return DateTime.now().difference(entry.createdAt) < expiry;
  }
  
  void _storeInMemoryCache(String key, dynamic data, String category) {
    // Check memory limits
    if (_memoryCache.length >= _maxCacheEntries) {
      _evictOldestEntry();
    }
    
    final expiry = _cacheExpiryTimes[category] ?? const Duration(hours: 1);
    _memoryCache[key] = CacheEntry(
      data: data,
      createdAt: DateTime.now(),
      expiry: expiry,
      category: category,
      size: _estimateDataSize(data),
    );
  }
  
  void _evictOldestEntry() {
    if (_memoryCache.isEmpty) return;
    
    String? oldestKey;
    DateTime? oldestTime;
    
    for (final entry in _memoryCache.entries) {
      final accessTime = _accessLog[entry.key];
      if (oldestTime == null || (accessTime != null && accessTime.isBefore(oldestTime))) {
        oldestTime = accessTime;
        oldestKey = entry.key;
      }
    }
    
    if (oldestKey != null) {
      _memoryCache.remove(oldestKey);
      _cacheEvictions++;
    }
  }
  
  Future<dynamic> _getPersistentCache(String key, Duration? customExpiry) async {
    final data = _prefs?.getString(key);
    final metadataStr = _prefs?.getString('${key}_metadata');
    
    if (data == null || metadataStr == null) return null;
    
    try {
      final metadata = jsonDecode(metadataStr) as Map<String, dynamic>;
      final createdAt = DateTime.parse(metadata['created_at']);
      final expiry = Duration(milliseconds: metadata['expiry_ms']);
      final isCompressed = metadata['compressed'] ?? false;
      
      final actualExpiry = customExpiry ?? expiry;
      if (DateTime.now().difference(createdAt) >= actualExpiry) {
        // Expired - remove it
        await _prefs?.remove(key);
        await _prefs?.remove('${key}_metadata');
        return null;
      }
      
      // Decompress if needed
      if (isCompressed) {
        final compressed = base64Decode(data);
        final decompressed = gzip.decode(compressed);
        return utf8.decode(decompressed);
      }
      
      return data;
    } catch (e) {
      debugPrint('IntelligentCacheService: Error reading persistent cache for $key: $e');
      return null;
    }
  }
  
  Future<void> _setPersistentCache(String key, dynamic data, Duration expiry, bool compress) async {
    try {
      String dataToStore = data.toString();
      bool isCompressed = false;
      
      // Compress large data
      if (compress || dataToStore.length > 1024) {
        final bytes = utf8.encode(dataToStore);
        final compressed = gzip.encode(bytes);
        dataToStore = base64Encode(compressed);
        isCompressed = true;
      }
      
      final metadata = {
        'created_at': DateTime.now().toIso8601String(),
        'expiry_ms': expiry.inMilliseconds,
        'compressed': isCompressed,
        'size': dataToStore.length,
      };
      
      await _prefs?.setString(key, dataToStore);
      await _prefs?.setString('${key}_metadata', jsonEncode(metadata));
    } catch (e) {
      debugPrint('IntelligentCacheService: Error storing persistent cache for $key: $e');
    }
  }
  
  String _serializeData<T>(T data) {
    if (data is String) return data;
    if (data is Map || data is List) return jsonEncode(data);
    return data.toString();
  }
  
  T? _deserializeData<T>(dynamic data) {
    if (data == null) return null;
    
    if (T == String) return data as T;
    if (T == int) return int.tryParse(data.toString()) as T?;
    if (T == double) return double.tryParse(data.toString()) as T?;
    if (T == bool) return (data.toString().toLowerCase() == 'true') as T;
    
    // Try to decode as JSON for complex types
    try {
      return jsonDecode(data.toString()) as T;
    } catch (e) {
      return data as T?;
    }
  }
  
  List<String> _getMostAccessedKeys() {
    final sortedEntries = _accessCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.map((e) => e.key).toList();
  }
  
  String _extractCategoryFromKey(String key) {
    if (!key.startsWith(_cachePrefix)) return 'default';
    final withoutPrefix = key.substring(_cachePrefix.length);
    final parts = withoutPrefix.split('_');
    return parts.isNotEmpty ? parts.first : 'default';
  }
  
  int _estimateDataSize(dynamic data) {
    if (data is String) return data.length;
    return data.toString().length;
  }
  
  double _estimateCacheSize() {
    int totalSize = 0;
    for (final entry in _memoryCache.values) {
      totalSize += entry.size;
    }
    return totalSize / (1024 * 1024); // Convert to MB
  }
  
  Future<void> _loadCacheMetadata() async {
    final metadataStr = _prefs?.getString(_metadataKey);
    if (metadataStr != null) {
      try {
        final metadata = jsonDecode(metadataStr) as Map<String, dynamic>;
        _cacheHits = metadata['cache_hits'] ?? 0;
        _cacheMisses = metadata['cache_misses'] ?? 0;
        _cacheEvictions = metadata['cache_evictions'] ?? 0;
      } catch (e) {
        debugPrint('IntelligentCacheService: Error loading cache metadata: $e');
      }
    }
  }
  
  Future<void> _loadAccessLog() async {
    final accessLogStr = _prefs?.getString(_accessLogKey);
    if (accessLogStr != null) {
      try {
        final accessData = jsonDecode(accessLogStr) as Map<String, dynamic>;
        for (final entry in accessData.entries) {
          _accessCount[entry.key] = entry.value as int;
        }
      } catch (e) {
        debugPrint('IntelligentCacheService: Error loading access log: $e');
      }
    }
  }
  
  Future<void> _saveCacheMetadata() async {
    final metadata = {
      'cache_hits': _cacheHits,
      'cache_misses': _cacheMisses,
      'cache_evictions': _cacheEvictions,
      'last_updated': DateTime.now().toIso8601String(),
    };
    await _prefs?.setString(_metadataKey, jsonEncode(metadata));
  }
  
  Future<void> _saveAccessLog() async {
    await _prefs?.setString(_accessLogKey, jsonEncode(_accessCount));
  }
  
  void _startPeriodicTasks() {
    // Cleanup expired entries every 30 minutes
    _cleanupTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      _cleanupExpiredEntries();
    });
    
    // Save metadata every 5 minutes
    Timer.periodic(const Duration(minutes: 5), (_) {
      _saveCacheMetadata();
      _saveAccessLog();
    });
    
    // Optimize cache every hour
    Timer.periodic(const Duration(hours: 1), (_) {
      optimizeCache();
    });
  }
  
  Future<void> _cleanupExpiredEntries() async {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    // Check memory cache
    for (final entry in _memoryCache.entries) {
      if (now.difference(entry.value.createdAt) >= entry.value.expiry) {
        expiredKeys.add(entry.key);
      }
    }
    
    // Remove expired entries
    for (final key in expiredKeys) {
      _memoryCache.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      debugPrint('IntelligentCacheService: Cleaned up ${expiredKeys.length} expired entries');
    }
  }
  
  Future<void> _compressLargeEntries() async {
    // This would compress large persistent cache entries
    // Implementation depends on specific requirements
  }
  
  Future<void> _evictLRUEntries() async {
    if (_memoryCache.length <= _maxCacheEntries) return;
    
    final sortedByAccess = _memoryCache.entries.toList()
      ..sort((a, b) {
        final aAccess = _accessLog[a.key] ?? DateTime(1970);
        final bAccess = _accessLog[b.key] ?? DateTime(1970);
        return aAccess.compareTo(bAccess);
      });
    
    final toEvict = sortedByAccess.length - _maxCacheEntries;
    for (int i = 0; i < toEvict; i++) {
      final key = sortedByAccess[i].key;
      _memoryCache.remove(key);
      _cacheEvictions++;
    }
    
    if (toEvict > 0) {
      debugPrint('IntelligentCacheService: Evicted $toEvict LRU entries');
    }
  }
}

/// Cache entry model
class CacheEntry {
  final dynamic data;
  final DateTime createdAt;
  final Duration expiry;
  final String category;
  final int size;
  
  CacheEntry({
    required this.data,
    required this.createdAt,
    required this.expiry,
    required this.category,
    required this.size,
  });
}

/// Cache categories for better organization
class CacheCategories {
  static const String userData = 'user_data';
  static const String taskData = 'task_data';
  static const String newsData = 'news_data';
  static const String settings = 'settings';
  static const String staticData = 'static_data';
  static const String temporary = 'temporary';
}