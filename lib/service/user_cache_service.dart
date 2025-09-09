// service/user_cache_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserCacheService {
  static final UserCacheService _instance = UserCacheService._internal();
  factory UserCacheService() => _instance;
  UserCacheService._internal();

  static const String _userDataKey = 'cached_user_data';
  static const String _userNamesKey = 'cached_user_names';
  static const String _userAvatarsKey = 'cached_user_avatars';
  static const String _lastUpdateKey = 'cache_last_update';
  static const String _currentUserKey = 'cached_current_user';
  
  // Cache expiry times
  static const Duration _userDataExpiry = Duration(hours: 6);
  static const Duration _userNamesExpiry = Duration(hours: 24);
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // In-memory cache for faster access
  Map<String, dynamic>? _currentUserData;
  Map<String, String> _userNamesCache = {};
  Map<String, String> _userAvatarsCache = {};
  DateTime? _lastUserDataUpdate;
  DateTime? _lastUserNamesUpdate;

  /// Initialize the cache service and load existing cached data
  Future<void> initialize() async {
    debugPrint('UserCacheService: Initializing cache service');
    await _loadCachedData();
    debugPrint('UserCacheService: Cache service initialized');
  }

  /// Get current user data from cache or fetch from Firebase
  Future<Map<String, dynamic>?> getCurrentUserData({bool forceRefresh = false}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('UserCacheService: No authenticated user');
      return null;
    }

    // Check if we have valid cached data
    if (!forceRefresh && _currentUserData != null && _isUserDataValid()) {
      debugPrint('UserCacheService: Returning cached user data');
      return Map<String, dynamic>.from(_currentUserData!);
    }

    // Fetch fresh data from Firebase
    debugPrint('UserCacheService: Fetching fresh user data from Firebase');
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        await _cacheCurrentUserData(userData);
        debugPrint('UserCacheService: User data cached successfully');
        return Map<String, dynamic>.from(userData);
      } else {
        debugPrint('UserCacheService: User document not found');
        return null;
      }
    } catch (e) {
      debugPrint('UserCacheService: Error fetching user data: $e');
      // Return cached data as fallback if available
      if (_currentUserData != null) {
        debugPrint('UserCacheService: Returning stale cached data as fallback');
        return Map<String, dynamic>.from(_currentUserData!);
      }
      return null;
    }
  }

  /// Get user name by ID from cache or fetch from Firebase
  Future<String> getUserName(String userId, {bool forceRefresh = false}) async {
    // Check cache first
    if (!forceRefresh && _userNamesCache.containsKey(userId) && _isUserNamesValid()) {
      return _userNamesCache[userId]!;
    }

    // Fetch from Firebase if not in cache or expired
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final fullName = userDoc.data()?['fullName'] ?? 'Unknown User';
        _userNamesCache[userId] = fullName;
        await _saveUserNamesCache();
        return fullName;
      }
    } catch (e) {
      debugPrint('UserCacheService: Error fetching user name for $userId: $e');
    }

    // Return cached value as fallback or default
    return _userNamesCache[userId] ?? 'Unknown User';
  }

  /// Get user name synchronously from cache only (for immediate UI display)
  String getUserNameSync(String userId) {
    return _userNamesCache[userId] ?? 'Unknown User';
  }

  /// Get user avatar synchronously from cache only (for immediate UI display)
  String getUserAvatarSync(String userId) {
    return _userAvatarsCache[userId] ?? '';
  }

  /// Check if user name is cached
  bool isUserNameCached(String userId) {
    return _userNamesCache.containsKey(userId);
  }

  /// Get user avatar by ID from cache or fetch from Firebase
  Future<String> getUserAvatar(String userId, {bool forceRefresh = false}) async {
    // Check cache first
    if (!forceRefresh && _userAvatarsCache.containsKey(userId) && _isUserNamesValid()) {
      return _userAvatarsCache[userId]!;
    }

    // Fetch from Firebase if not in cache or expired
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final photoUrl = _validateAvatarUrl(userDoc.data()?['photoUrl']);
        _userAvatarsCache[userId] = photoUrl;
        await _saveUserAvatarsCache();
        return photoUrl;
      }
    } catch (e) {
      debugPrint('UserCacheService: Error fetching user avatar for $userId: $e');
    }

    // Return cached value as fallback or default
    return _userAvatarsCache[userId] ?? '';
  }

  /// Pre-fetch all user names and avatars for better performance
  Future<void> preFetchAllUsers({bool forceRefresh = false}) async {
    if (!forceRefresh && _isUserNamesValid()) {
      debugPrint('UserCacheService: User names cache is still valid, skipping pre-fetch');
      return;
    }

    debugPrint('UserCacheService: Pre-fetching all user names and avatars');
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      
      for (final doc in usersSnapshot.docs) {
        final data = doc.data();
        final userId = doc.id;
        final fullName = data['fullName'] ?? 'Unknown User';
        final photoUrl = _validateAvatarUrl(data['photoUrl']);
        
        _userNamesCache[userId] = fullName;
        _userAvatarsCache[userId] = photoUrl;
      }
      
      await _saveUserNamesCache();
      await _saveUserAvatarsCache();
      _lastUserNamesUpdate = DateTime.now();
      
      debugPrint('UserCacheService: Pre-fetched ${_userNamesCache.length} users');
    } catch (e) {
      debugPrint('UserCacheService: Error pre-fetching users: $e');
    }
  }

  /// Update cached user data when new data is available
  Future<void> updateCurrentUserData(Map<String, dynamic> userData) async {
    debugPrint('UserCacheService: Updating cached user data');
    await _cacheCurrentUserData(userData);
  }

  /// Update user avatar in cache
  Future<void> updateUserAvatar(String userId, String avatarUrl) async {
    try {
      _userAvatarsCache[userId] = _validateAvatarUrl(avatarUrl);
      
      // If this is the current user, also update current user cache
      if (_auth.currentUser?.uid == userId && _currentUserData != null) {
        _currentUserData!['photoUrl'] = avatarUrl;
        _lastUserDataUpdate = DateTime.now();
        await _cacheCurrentUserData(_currentUserData!);
      }
      
      await _saveUserAvatarsCache();
      debugPrint('UserCacheService: User avatar updated for $userId');
    } catch (e) {
      debugPrint('UserCacheService: Error updating user avatar: $e');
    }
  }

  /// Update cached user name and avatar
  Future<void> updateUserInfo(String userId, {String? fullName, String? photoUrl}) async {
    if (fullName != null) {
      _userNamesCache[userId] = fullName;
    }
    if (photoUrl != null) {
      _userAvatarsCache[userId] = _validateAvatarUrl(photoUrl);
    }
    
    await _saveUserNamesCache();
    await _saveUserAvatarsCache();
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    debugPrint('UserCacheService: Clearing all cached data');
    final prefs = await SharedPreferences.getInstance();
    
    await Future.wait([
      prefs.remove(_userDataKey),
      prefs.remove(_userNamesKey),
      prefs.remove(_userAvatarsKey),
      prefs.remove(_lastUpdateKey),
      prefs.remove(_currentUserKey),
    ]);
    
    _currentUserData = null;
    _userNamesCache.clear();
    _userAvatarsCache.clear();
    _lastUserDataUpdate = null;
    _lastUserNamesUpdate = null;
  }

  /// Clear cache for a specific user (useful when user logs out)
  Future<void> clearUserCache(String userId) async {
    debugPrint('UserCacheService: Clearing cache for user $userId');
    
    if (_auth.currentUser?.uid == userId) {
      _currentUserData = null;
      _lastUserDataUpdate = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataKey);
      await prefs.remove(_currentUserKey);
    }
  }

  // Private helper methods
  
  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load current user data
    final userDataString = prefs.getString(_userDataKey);
    final lastUpdateString = prefs.getString(_lastUpdateKey);
    
    if (userDataString != null && lastUpdateString != null) {
      try {
        _currentUserData = Map<String, dynamic>.from(jsonDecode(userDataString));
        _lastUserDataUpdate = DateTime.parse(lastUpdateString);
      } catch (e) {
        debugPrint('UserCacheService: Error loading cached user data: $e');
      }
    }
    
    // Load user names cache
    final userNamesString = prefs.getString(_userNamesKey);
    if (userNamesString != null) {
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(userNamesString));
        _userNamesCache = Map<String, String>.from(decoded);
      } catch (e) {
        debugPrint('UserCacheService: Error loading cached user names: $e');
      }
    }
    
    // Load user avatars cache
    final userAvatarsString = prefs.getString(_userAvatarsKey);
    if (userAvatarsString != null) {
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(userAvatarsString));
        _userAvatarsCache = Map<String, String>.from(decoded);
      } catch (e) {
        debugPrint('UserCacheService: Error loading cached user avatars: $e');
      }
    }
  }
  
  Future<void> _cacheCurrentUserData(Map<String, dynamic> userData) async {
    _currentUserData = Map<String, dynamic>.from(userData);
    _lastUserDataUpdate = DateTime.now();
    
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_userDataKey, jsonEncode(userData)),
      prefs.setString(_lastUpdateKey, _lastUserDataUpdate!.toIso8601String()),
      prefs.setString(_currentUserKey, _auth.currentUser?.uid ?? ''),
    ]);
  }
  
  Future<void> _saveUserNamesCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNamesKey, jsonEncode(_userNamesCache));
  }
  
  Future<void> _saveUserAvatarsCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userAvatarsKey, jsonEncode(_userAvatarsCache));
  }
  
  bool _isUserDataValid() {
    if (_lastUserDataUpdate == null) return false;
    return DateTime.now().difference(_lastUserDataUpdate!) < _userDataExpiry;
  }
  
  bool _isUserNamesValid() {
    if (_lastUserNamesUpdate == null) return false;
    return DateTime.now().difference(_lastUserNamesUpdate!) < _userNamesExpiry;
  }
  
  String _validateAvatarUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    
    // If it's already a valid network URL, return it
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    
    // If it's a local file path, return empty string
    if (url.startsWith('file://') || url.startsWith('/')) {
      return '';
    }
    
    return '';
  }



  // Getters for debugging and monitoring
  int get cachedUserAvatarsCount => _userAvatarsCache.length;
  bool get hasCurrentUserData => _currentUserData != null;
  DateTime? get lastUserDataUpdate => _lastUserDataUpdate;
  DateTime? get lastUserNamesUpdate => _lastUserNamesUpdate;
}