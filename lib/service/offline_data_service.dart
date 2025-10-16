import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'network_service.dart';
import '../utils/snackbar_utils.dart';

enum SyncStatus { pending, syncing, synced, failed }

class OfflineDataItem {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final String? syncError;

  OfflineDataItem({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.syncError,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'data': jsonEncode(data),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'sync_status': syncStatus.index,
      'sync_error': syncError,
    };
  }

  factory OfflineDataItem.fromMap(Map<String, dynamic> map) {
    return OfflineDataItem(
      id: map['id'],
      type: map['type'],
      data: jsonDecode(map['data']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      syncStatus: SyncStatus.values[map['sync_status']],
      syncError: map['sync_error'],
    );
  }

  OfflineDataItem copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    String? syncError,
  }) {
    return OfflineDataItem(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
    );
  }
}

class OfflineDataService extends GetxService {
  static OfflineDataService get to => Get.find();

  Database? _database;
  SharedPreferences? _prefs;
  Timer? _syncTimer;

  final RxBool _isSyncing = false.obs;
  final RxInt _pendingItemsCount = 0.obs;
  final RxString _lastSyncTime = ''.obs;

  // Getters
  bool get isSyncing => _isSyncing.value;
  int get pendingItemsCount => _pendingItemsCount.value;
  String get lastSyncTime => _lastSyncTime.value;

  // Observables
  RxBool get isSyncingObs => _isSyncing;
  RxInt get pendingItemsCountObs => _pendingItemsCount;
  RxString get lastSyncTimeObs => _lastSyncTime;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeDatabase();
    await _initializePreferences();
    await _loadLastSyncTime();
    await _updatePendingCount();
    _startPeriodicSync();
  }

  @override
  void onClose() {
    _syncTimer?.cancel();
    _database?.close();
    super.onClose();
  }

  Future<void> _initializeDatabase() async {
    try {
      // Compute database path depending on platform
      String path;
      if (kIsWeb) {
        // On web, use a simple database name. Storage is handled by IndexedDB.
        path = 'offline_data.db';
      } else {
        final databasesPath = await getDatabasesPath();
        path = join(databasesPath, 'offline_data.db');
      }

      _database = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE offline_data (
              id TEXT PRIMARY KEY,
              type TEXT NOT NULL,
              data TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              sync_status INTEGER NOT NULL,
              sync_error TEXT
            )
          ''');

          await db.execute('''
            CREATE INDEX idx_type ON offline_data(type)
          ''');

          await db.execute('''
            CREATE INDEX idx_sync_status ON offline_data(sync_status)
          ''');
        },
      );
    } catch (e) {
      debugPrint('Error initializing offline database: $e');
    }
  }

  Future<void> _initializePreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('Error initializing shared preferences: $e');
    }
  }

  Future<void> _loadLastSyncTime() async {
    try {
      final lastSync = _prefs?.getString('last_sync_time');
      if (lastSync != null) {
        _lastSyncTime.value = lastSync;
      }
    } catch (e) {
      debugPrint('Error loading last sync time: $e');
    }
  }

  Future<void> _updatePendingCount() async {
    try {
      if (_database == null) return;

      final result = await _database!.rawQuery(
        'SELECT COUNT(*) as count FROM offline_data WHERE sync_status = ?',
        [SyncStatus.pending.index],
      );

      _pendingItemsCount.value = result.first['count'] as int? ?? 0;
    } catch (e) {
      debugPrint('Error updating pending count: $e');
    }
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => syncPendingData(),
    );
  }

  // Cache data for offline use
  Future<void> cacheData(
      String type, String id, Map<String, dynamic> data) async {
    try {
      if (_database == null) return;

      final item = OfflineDataItem(
        id: id,
        type: type,
        data: data,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
      );

      await _database!.insert(
        'offline_data',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error caching data: $e');
    }
  }

  // Store data for later sync when online
  Future<void> storeForSync(
      String type, String id, Map<String, dynamic> data) async {
    try {
      if (_database == null) return;

      final item = OfflineDataItem(
        id: id,
        type: type,
        data: data,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      await _database!.insert(
        'offline_data',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await _updatePendingCount();
    } catch (e) {
      debugPrint('Error storing data for sync: $e');
    }
  }

  // Retrieve cached data
  Future<Map<String, dynamic>?> getCachedData(String type, String id) async {
    try {
      if (_database == null) return null;

      final result = await _database!.query(
        'offline_data',
        where: 'type = ? AND id = ?',
        whereArgs: [type, id],
        limit: 1,
      );

      if (result.isNotEmpty) {
        final item = OfflineDataItem.fromMap(result.first);
        return item.data;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting cached data: $e');
      return null;
    }
  }

  // Get all cached data of a specific type
  Future<List<Map<String, dynamic>>> getCachedDataByType(String type) async {
    try {
      if (_database == null) return [];

      final result = await _database!.query(
        'offline_data',
        where: 'type = ? AND sync_status = ?',
        whereArgs: [type, SyncStatus.synced.index],
        orderBy: 'updated_at DESC',
      );

      return result.map((map) {
        final item = OfflineDataItem.fromMap(map);
        return item.data;
      }).toList();
    } catch (e) {
      debugPrint('Error getting cached data by type: $e');
      return [];
    }
  }

  // Sync pending data when online
  Future<void> syncPendingData() async {
    if (_isSyncing.value || !NetworkService.to.isOnline) {
      return;
    }

    try {
      _isSyncing.value = true;

      if (_database == null) return;

      final pendingItems = await _database!.query(
        'offline_data',
        where: 'sync_status = ?',
        whereArgs: [SyncStatus.pending.index],
        orderBy: 'created_at ASC',
      );

      if (pendingItems.isEmpty) {
        _updateLastSyncTime();
        return;
      }

      for (final itemMap in pendingItems) {
        final item = OfflineDataItem.fromMap(itemMap);

        try {
          // Mark as syncing
          await _updateSyncStatus(item.id, SyncStatus.syncing);

          // Attempt to sync the item
          final success = await _syncItem(item);

          if (success) {
            // Mark as synced
            await _updateSyncStatus(item.id, SyncStatus.synced);
          } else {
            // Mark as failed
            await _updateSyncStatus(
                item.id, SyncStatus.failed, 'Sync operation failed');
          }
        } catch (e) {
          // Mark as failed with error
          await _updateSyncStatus(item.id, SyncStatus.failed, e.toString());
        }
      }

      await _updatePendingCount();
      _updateLastSyncTime();
    } catch (e) {
      debugPrint('Error syncing pending data: $e');
    } finally {
      _isSyncing.value = false;
    }
  }

  Future<bool> _syncItem(OfflineDataItem item) async {
    // This is a placeholder - implement actual sync logic based on item type
    // You would typically call your API endpoints here

    switch (item.type) {
      case 'task':
        return await _syncTask(item);
      case 'user':
        return await _syncUser(item);
      case 'message':
        return await _syncMessage(item);
      default:
        debugPrint('Unknown item type for sync: ${item.type}');
        return false;
    }
  }

  Future<bool> _syncTask(OfflineDataItem item) async {
    // Implement task sync logic
    // Example: call TaskService.syncTask(item.data)
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
    return true; // Return actual result
  }

  Future<bool> _syncUser(OfflineDataItem item) async {
    // Implement user sync logic
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
    return true; // Return actual result
  }

  Future<bool> _syncMessage(OfflineDataItem item) async {
    // Implement message sync logic
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
    return true; // Return actual result
  }

  Future<void> _updateSyncStatus(String id, SyncStatus status,
      [String? error]) async {
    try {
      if (_database == null) return;

      await _database!.update(
        'offline_data',
        {
          'sync_status': status.index,
          'sync_error': error,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Error updating sync status: $e');
    }
  }

  void _updateLastSyncTime() {
    try {
      final now = DateTime.now().toIso8601String();
      _lastSyncTime.value = now;
      _prefs?.setString('last_sync_time', now);
    } catch (e) {
      debugPrint('Error updating last sync time: $e');
    }
  }

  // Manual sync trigger
  Future<void> forcSync() async {
    if (!NetworkService.to.isOnline) {
      SnackbarUtils.showWarning('sync_requires_network'.tr);
      return;
    }

    await syncPendingData();
    SnackbarUtils.showSuccess('sync_completed'.tr);
  }

  // Clear all cached data
  Future<void> clearCache() async {
    try {
      if (_database == null) return;

      await _database!.delete('offline_data');
      await _updatePendingCount();
      _lastSyncTime.value = '';
      _prefs?.remove('last_sync_time');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  // Clear only synced data (keep pending items)
  Future<void> clearSyncedCache() async {
    try {
      if (_database == null) return;

      await _database!.delete(
        'offline_data',
        where: 'sync_status = ?',
        whereArgs: [SyncStatus.synced.index],
      );
    } catch (e) {
      debugPrint('Error clearing synced cache: $e');
    }
  }

  // Get sync statistics
  Future<Map<String, int>> getSyncStats() async {
    try {
      if (_database == null) {
        return {
          'total': 0,
          'pending': 0,
          'syncing': 0,
          'synced': 0,
          'failed': 0,
        };
      }

      final result = await _database!.rawQuery('''
        SELECT 
          sync_status,
          COUNT(*) as count
        FROM offline_data 
        GROUP BY sync_status
      ''');

      final stats = <String, int>{
        'total': 0,
        'pending': 0,
        'syncing': 0,
        'synced': 0,
        'failed': 0,
      };

      for (final row in result) {
        final status = SyncStatus.values[row['sync_status'] as int];
        final count = row['count'] as int;

        stats['total'] = (stats['total'] ?? 0) + count;

        switch (status) {
          case SyncStatus.pending:
            stats['pending'] = count;
            break;
          case SyncStatus.syncing:
            stats['syncing'] = count;
            break;
          case SyncStatus.synced:
            stats['synced'] = count;
            break;
          case SyncStatus.failed:
            stats['failed'] = count;
            break;
        }
      }

      return stats;
    } catch (e) {
      debugPrint('Error getting sync stats: $e');
      return {
        'total': 0,
        'pending': 0,
        'syncing': 0,
        'synced': 0,
        'failed': 0,
      };
    }
  }
}

// Mixin for offline-aware widgets
mixin OfflineAwareMixin {
  OfflineDataService get offlineService => OfflineDataService.to;
  NetworkService get networkService => NetworkService.to;

  bool get isOnline => networkService.isOnline;
  bool get hasPendingSync => offlineService.pendingItemsCount > 0;

  Future<T?> executeOfflineCapable<T>(
    Future<T> Function() onlineOperation,
    Future<T?> Function() offlineOperation,
  ) async {
    if (isOnline) {
      try {
        return await onlineOperation();
      } catch (e) {
        // If online operation fails, try offline
        return await offlineOperation();
      }
    } else {
      return await offlineOperation();
    }
  }

  void showOfflineMessage() {
    SnackbarUtils.showWarning('offline_mode_message'.tr);
  }
}
