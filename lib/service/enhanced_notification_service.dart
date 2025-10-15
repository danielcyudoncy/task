// service/enhanced_notification_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enhanced notification service with rich feedback mechanisms
class EnhancedNotificationService extends GetxService {
  static final EnhancedNotificationService _instance =
      EnhancedNotificationService._internal();
  factory EnhancedNotificationService() => _instance;
  EnhancedNotificationService._internal();

  // Notification queue and management
  final List<NotificationItem> _notificationQueue = [];
  final StreamController<NotificationItem> _notificationController =
      StreamController<NotificationItem>.broadcast();
  final StreamController<List<NotificationItem>> _queueController =
      StreamController<List<NotificationItem>>.broadcast();

  // Configuration
  final RxBool _isEnabled = true.obs;
  final RxBool _soundEnabled = true.obs;
  final RxBool _vibrationEnabled = true.obs;
  final RxInt _maxQueueSize = 50.obs;
  final RxInt _autoHideDuration = 5.obs; // seconds

  // Statistics
  final RxInt _totalNotifications = 0.obs;
  final RxInt _dismissedNotifications = 0.obs;
  final RxInt _actionedNotifications = 0.obs;

  // Streams
  Stream<NotificationItem> get notificationStream =>
      _notificationController.stream;
  Stream<List<NotificationItem>> get queueStream => _queueController.stream;

  // Getters
  bool get isEnabled => _isEnabled.value;
  bool get soundEnabled => _soundEnabled.value;
  bool get vibrationEnabled => _vibrationEnabled.value;
  int get maxQueueSize => _maxQueueSize.value;
  int get autoHideDuration => _autoHideDuration.value;
  List<NotificationItem> get notifications =>
      List.unmodifiable(_notificationQueue);

  // Statistics getters
  int get totalNotifications => _totalNotifications.value;
  int get dismissedNotifications => _dismissedNotifications.value;
  int get actionedNotifications => _actionedNotifications.value;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadSettings();
    _startPeriodicCleanup();
  }

  @override
  void onClose() {
    _notificationController.close();
    _queueController.close();
    super.onClose();
  }

  /// Show a success notification
  void showSuccess({
    required String message,
    String? title,
    Duration? duration,
    VoidCallback? onTap,
    List<NotificationAction>? actions,
  }) {
    _showNotification(
      NotificationItem(
        id: _generateId(),
        type: NotificationType.success,
        title: title ?? 'success'.tr,
        message: message,
        duration: duration ?? Duration(seconds: autoHideDuration),
        onTap: onTap,
        actions: actions,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Show an error notification
  void showError({
    required String message,
    String? title,
    Duration? duration,
    VoidCallback? onTap,
    List<NotificationAction>? actions,
    bool persistent = false,
  }) {
    _showNotification(
      NotificationItem(
        id: _generateId(),
        type: NotificationType.error,
        title: title ?? 'error'.tr,
        message: message,
        duration: persistent
            ? null
            : (duration ?? Duration(seconds: autoHideDuration * 2)),
        onTap: onTap,
        actions: actions,
        timestamp: DateTime.now(),
        priority: NotificationPriority.high,
      ),
    );
  }

  /// Show a warning notification
  void showWarning({
    required String message,
    String? title,
    Duration? duration,
    VoidCallback? onTap,
    List<NotificationAction>? actions,
  }) {
    _showNotification(
      NotificationItem(
        id: _generateId(),
        type: NotificationType.warning,
        title: title ?? 'warning'.tr,
        message: message,
        duration: duration ?? Duration(seconds: autoHideDuration),
        onTap: onTap,
        actions: actions,
        timestamp: DateTime.now(),
        priority: NotificationPriority.medium,
      ),
    );
  }

  /// Show an info notification
  void showInfo({
    required String message,
    String? title,
    Duration? duration,
    VoidCallback? onTap,
    List<NotificationAction>? actions,
  }) {
    _showNotification(
      NotificationItem(
        id: _generateId(),
        type: NotificationType.info,
        title: title ?? 'info'.tr,
        message: message,
        duration: duration ?? Duration(seconds: autoHideDuration),
        onTap: onTap,
        actions: actions,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Show a loading notification
  String showLoading({
    required String message,
    String? title,
    VoidCallback? onCancel,
  }) {
    final notification = NotificationItem(
      id: _generateId(),
      type: NotificationType.loading,
      title: title ?? 'loading'.tr,
      message: message,
      duration: null, // Persistent until dismissed
      actions: onCancel != null
          ? [
              NotificationAction(
                label: 'cancel'.tr,
                onPressed: onCancel,
                isDestructive: true,
              ),
            ]
          : null,
      timestamp: DateTime.now(),
      priority: NotificationPriority.medium,
    );

    _showNotification(notification);
    return notification.id;
  }

  /// Update a loading notification
  void updateLoading(
    String id, {
    String? message,
    double? progress,
  }) {
    final index = _notificationQueue.indexWhere((n) => n.id == id);
    if (index != -1) {
      final notification = _notificationQueue[index];
      if (notification.type == NotificationType.loading) {
        final updated = notification.copyWith(
          message: message ?? notification.message,
          progress: progress ?? notification.progress,
        );
        _notificationQueue[index] = updated;
        _queueController.add(List.from(_notificationQueue));
      }
    }
  }

  /// Hide a loading notification
  void hideLoading(String id) {
    dismissNotification(id);
  }

  /// Show a confirmation dialog
  Future<bool> showConfirmation({
    required String message,
    String? title,
    String? confirmText,
    String? cancelText,
    bool isDestructive = false,
  }) async {
    final completer = Completer<bool>();
    final notificationId = _generateId();

    final notification = NotificationItem(
      id: notificationId,
      type: NotificationType.confirmation,
      title: title ?? 'confirm'.tr,
      message: message,
      duration: null, // Persistent until action
      actions: [
        NotificationAction(
          label: cancelText ?? 'cancel'.tr,
          onPressed: () {
            completer.complete(false);
            dismissNotification(notificationId);
          },
        ),
        NotificationAction(
          label: confirmText ?? 'confirm'.tr,
          onPressed: () {
            completer.complete(true);
            dismissNotification(notificationId);
          },
          isPrimary: true,
          isDestructive: isDestructive,
        ),
      ],
      timestamp: DateTime.now(),
      priority: NotificationPriority.high,
    );

    _showNotification(notification);
    return completer.future;
  }

  /// Show a custom notification
  void showCustom(NotificationItem notification) {
    _showNotification(notification);
  }

  /// Dismiss a specific notification
  void dismissNotification(String id) {
    final index = _notificationQueue.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notificationQueue.removeAt(index);
      _dismissedNotifications.value++;
      _queueController.add(List.from(_notificationQueue));
    }
  }

  /// Dismiss all notifications
  void dismissAll() {
    _dismissedNotifications.value += _notificationQueue.length;
    _notificationQueue.clear();
    _queueController.add(List.from(_notificationQueue));
  }

  /// Dismiss notifications by type
  void dismissByType(NotificationType type) {
    final toRemove = _notificationQueue.where((n) => n.type == type).length;
    _notificationQueue.removeWhere((n) => n.type == type);
    _dismissedNotifications.value += toRemove;
    _queueController.add(List.from(_notificationQueue));
  }

  /// Mark notification as actioned
  void markAsActioned(String id) {
    final notification = _notificationQueue.firstWhereOrNull((n) => n.id == id);
    if (notification != null) {
      _actionedNotifications.value++;
    }
  }

  /// Get notification statistics
  Map<String, dynamic> getStatistics() {
    final activeCount = _notificationQueue.length;
    final totalShown = totalNotifications;
    final dismissRate =
        totalShown > 0 ? (dismissedNotifications / totalShown * 100) : 0.0;
    final actionRate =
        totalShown > 0 ? (actionedNotifications / totalShown * 100) : 0.0;

    return {
      'total_notifications': totalShown,
      'active_notifications': activeCount,
      'dismissed_notifications': dismissedNotifications,
      'actioned_notifications': actionedNotifications,
      'dismiss_rate': dismissRate.toStringAsFixed(1),
      'action_rate': actionRate.toStringAsFixed(1),
      'queue_utilization': maxQueueSize > 0
          ? (activeCount / maxQueueSize * 100).toStringAsFixed(1)
          : '0.0',
      'types_breakdown': _getTypesBreakdown(),
    };
  }

  /// Configure notification settings
  Future<void> updateSettings({
    bool? enabled,
    bool? sound,
    bool? vibration,
    int? maxQueue,
    int? autoHide,
  }) async {
    if (enabled != null) _isEnabled.value = enabled;
    if (sound != null) _soundEnabled.value = sound;
    if (vibration != null) _vibrationEnabled.value = vibration;
    if (maxQueue != null) _maxQueueSize.value = maxQueue;
    if (autoHide != null) _autoHideDuration.value = autoHide;

    await _saveSettings();
  }

  /// Get current settings
  Map<String, dynamic> getSettings() {
    return {
      'enabled': isEnabled,
      'sound_enabled': soundEnabled,
      'vibration_enabled': vibrationEnabled,
      'max_queue_size': maxQueueSize,
      'auto_hide_duration': autoHideDuration,
    };
  }

  // Private methods

  void _showNotification(NotificationItem notification) {
    if (!isEnabled) return;

    // Manage queue size
    if (_notificationQueue.length >= maxQueueSize) {
      // Remove oldest low-priority notification
      final oldestLowPriority = _notificationQueue
          .where((n) => n.priority == NotificationPriority.low)
          .firstOrNull;

      if (oldestLowPriority != null) {
        _notificationQueue.remove(oldestLowPriority);
      } else {
        // Remove oldest notification if no low priority found
        _notificationQueue.removeAt(0);
      }
    }

    // Add to queue based on priority
    if (notification.priority == NotificationPriority.high) {
      _notificationQueue.insert(0, notification);
    } else {
      _notificationQueue.add(notification);
    }

    _totalNotifications.value++;

    // Emit events
    _notificationController.add(notification);
    _queueController.add(List.from(_notificationQueue));

    // Auto-dismiss if duration is set
    if (notification.duration != null) {
      Timer(notification.duration!, () {
        dismissNotification(notification.id);
      });
    }

    debugPrint(
        'EnhancedNotificationService: Showed ${notification.type.name} notification: ${notification.message}');
  }

  String _generateId() {
    return 'notification_${DateTime.now().millisecondsSinceEpoch}_${_totalNotifications.value}';
  }

  Map<String, int> _getTypesBreakdown() {
    final breakdown = <String, int>{};
    for (final notification in _notificationQueue) {
      final type = notification.type.name;
      breakdown[type] = (breakdown[type] ?? 0) + 1;
    }
    return breakdown;
  }

  void _startPeriodicCleanup() {
    Timer.periodic(const Duration(minutes: 5), (timer) {
      final now = DateTime.now();
      final expiredCount = _notificationQueue.length;

      // Remove expired notifications (older than 1 hour)
      _notificationQueue.removeWhere((notification) {
        return now.difference(notification.timestamp).inHours > 1;
      });

      final removedCount = expiredCount - _notificationQueue.length;
      if (removedCount > 0) {
        _queueController.add(List.from(_notificationQueue));
        debugPrint(
            'EnhancedNotificationService: Cleaned up $removedCount expired notifications');
      }
    });
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _isEnabled.value = prefs.getBool('notification_enabled') ?? true;
      _soundEnabled.value = prefs.getBool('notification_sound') ?? true;
      _vibrationEnabled.value = prefs.getBool('notification_vibration') ?? true;
      _maxQueueSize.value = prefs.getInt('notification_max_queue') ?? 50;
      _autoHideDuration.value = prefs.getInt('notification_auto_hide') ?? 5;

      debugPrint('EnhancedNotificationService: Settings loaded');
    } catch (e) {
      debugPrint('EnhancedNotificationService: Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('notification_enabled', isEnabled);
      await prefs.setBool('notification_sound', soundEnabled);
      await prefs.setBool('notification_vibration', vibrationEnabled);
      await prefs.setInt('notification_max_queue', maxQueueSize);
      await prefs.setInt('notification_auto_hide', autoHideDuration);

      debugPrint('EnhancedNotificationService: Settings saved');
    } catch (e) {
      debugPrint('EnhancedNotificationService: Error saving settings: $e');
    }
  }
}

/// Notification item model
class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final Duration? duration;
  final VoidCallback? onTap;
  final List<NotificationAction>? actions;
  final DateTime timestamp;
  final NotificationPriority priority;
  final double? progress;
  final Map<String, dynamic>? metadata;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.duration,
    this.onTap,
    this.actions,
    required this.timestamp,
    this.priority = NotificationPriority.medium,
    this.progress,
    this.metadata,
  });

  NotificationItem copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    Duration? duration,
    VoidCallback? onTap,
    List<NotificationAction>? actions,
    DateTime? timestamp,
    NotificationPriority? priority,
    double? progress,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      duration: duration ?? this.duration,
      onTap: onTap ?? this.onTap,
      actions: actions ?? this.actions,
      timestamp: timestamp ?? this.timestamp,
      priority: priority ?? this.priority,
      progress: progress ?? this.progress,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Notification action model
class NotificationAction {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDestructive;
  final IconData? icon;

  const NotificationAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
    this.icon,
  });
}

/// Notification types
enum NotificationType {
  success,
  error,
  warning,
  info,
  loading,
  confirmation,
  custom,
}

/// Notification priorities
enum NotificationPriority {
  low,
  medium,
  high,
}
