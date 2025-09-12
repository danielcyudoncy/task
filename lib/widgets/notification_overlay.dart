// widgets/notification_overlay.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../service/enhanced_notification_service.dart';

/// Overlay widget that displays notifications
class NotificationOverlay extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Alignment alignment;
  final int maxVisible;
  
  const NotificationOverlay({
    super.key,
    required this.child,
    this.padding,
    this.alignment = Alignment.topRight,
    this.maxVisible = 3,
  });
  
  @override
  State<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<NotificationOverlay>
    with TickerProviderStateMixin {
  final EnhancedNotificationService _notificationService = Get.find<EnhancedNotificationService>();
  
  final List<NotificationItem> _visibleNotifications = [];
  final Map<String, AnimationController> _animationControllers = {};
  final Map<String, Animation<Offset>> _slideAnimations = {};
  final Map<String, Animation<double>> _fadeAnimations = {};
  
  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
  }
  
  @override
  void dispose() {
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
        // Notification overlay
        Positioned.fill(
          child: IgnorePointer(
            ignoring: _visibleNotifications.isEmpty,
            child: Container(
              padding: widget.padding ?? const EdgeInsets.all(16),
              child: Align(
                alignment: widget.alignment,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: _getCrossAxisAlignment(),
                  children: _visibleNotifications.take(widget.maxVisible).map((notification) {
                    return _buildNotificationCard(notification);
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildNotificationCard(NotificationItem notification) {
    final slideAnimation = _slideAnimations[notification.id];
    final fadeAnimation = _fadeAnimations[notification.id];
    
    if (slideAnimation == null || fadeAnimation == null) {
      return const SizedBox.shrink();
    }
    
    return AnimatedBuilder(
      animation: Listenable.merge([slideAnimation, fadeAnimation]),
      builder: (context, child) {
        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              constraints: const BoxConstraints(
                maxWidth: 400,
                minWidth: 300,
              ),
              child: _buildNotificationContent(notification),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildNotificationContent(NotificationItem notification) {
    return Card(
      elevation: 8,
      shadowColor: _getNotificationColor(notification.type).withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getNotificationColor(notification.type).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          notification.onTap?.call();
          _notificationService.markAsActioned(notification.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getNotificationColor(notification.type).withValues(alpha: 0.05),
                _getNotificationColor(notification.type).withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.type),
                      color: _getNotificationColor(notification.type),
                      size: 20,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Title and timestamp
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _getNotificationColor(notification.type),
                          ),
                        ),
                        Text(
                          _formatTimestamp(notification.timestamp),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Close button
                  IconButton(
                    onPressed: () => _dismissNotification(notification.id),
                    icon: const Icon(Icons.close),
                    iconSize: 18,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                    color: Theme.of(context).disabledColor,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Message
              Text(
                notification.message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              
              // Progress bar for loading notifications
              if (notification.type == NotificationType.loading && notification.progress != null)
                const SizedBox(height: 12),
              if (notification.type == NotificationType.loading && notification.progress != null)
                LinearProgressIndicator(
                  value: notification.progress,
                  backgroundColor: _getNotificationColor(notification.type).withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getNotificationColor(notification.type),
                  ),
                ),
              
              // Actions
              if (notification.actions != null && notification.actions!.isNotEmpty)
                const SizedBox(height: 16),
              if (notification.actions != null && notification.actions!.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: notification.actions!.map((action) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _buildActionButton(action, notification),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButton(NotificationAction action, NotificationItem notification) {
    if (action.isPrimary) {
      return ElevatedButton.icon(
        onPressed: () {
          action.onPressed();
          _notificationService.markAsActioned(notification.id);
        },
        icon: action.icon != null ? Icon(action.icon, size: 16) : null,
        label: Text(action.label),
        style: ElevatedButton.styleFrom(
          backgroundColor: action.isDestructive 
              ? Theme.of(context).colorScheme.error
              : _getNotificationColor(notification.type),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: () {
          action.onPressed();
          _notificationService.markAsActioned(notification.id);
        },
        icon: action.icon != null ? Icon(action.icon, size: 16) : null,
        label: Text(action.label),
        style: OutlinedButton.styleFrom(
          foregroundColor: action.isDestructive 
              ? Theme.of(context).colorScheme.error
              : _getNotificationColor(notification.type),
          side: BorderSide(
            color: action.isDestructive 
                ? Theme.of(context).colorScheme.error
                : _getNotificationColor(notification.type),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );
    }
  }
  
  // Helper methods
  
  CrossAxisAlignment _getCrossAxisAlignment() {
    switch (widget.alignment) {
      case Alignment.topLeft:
      case Alignment.centerLeft:
      case Alignment.bottomLeft:
        return CrossAxisAlignment.start;
      case Alignment.topRight:
      case Alignment.centerRight:
      case Alignment.bottomRight:
        return CrossAxisAlignment.end;
      default:
        return CrossAxisAlignment.center;
    }
  }
  
  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Colors.green;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.info:
        return Colors.blue;
      case NotificationType.loading:
        return Colors.purple;
      case NotificationType.confirmation:
        return Colors.amber;
      case NotificationType.custom:
        return Theme.of(context).primaryColor;
    }
  }
  
  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.info:
        return Icons.info;
      case NotificationType.loading:
        return Icons.hourglass_empty;
      case NotificationType.confirmation:
        return Icons.help;
      case NotificationType.custom:
        return Icons.notifications;
    }
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return 'just_now'.tr;
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ${'ago'.tr}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ${'ago'.tr}';
    } else {
      return '${difference.inDays}d ${'ago'.tr}';
    }
  }
  
  // Animation and lifecycle methods
  
  void _setupNotificationListener() {
    _notificationService.notificationStream.listen((notification) {
      _showNotification(notification);
    });
    
    _notificationService.queueStream.listen((notifications) {
      _updateVisibleNotifications(notifications);
    });
  }
  
  void _showNotification(NotificationItem notification) {
    if (!mounted) return;
    
    // Create animation controller
    final controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Create animations
    final slideAnimation = Tween<Offset>(
      begin: _getSlideBeginOffset(),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutBack,
    ));
    
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));
    
    // Store animations
    _animationControllers[notification.id] = controller;
    _slideAnimations[notification.id] = slideAnimation;
    _fadeAnimations[notification.id] = fadeAnimation;
    
    // Add to visible list
    setState(() {
      _visibleNotifications.insert(0, notification);
    });
    
    // Start animation
    controller.forward();
  }
  
  void _dismissNotification(String id) {
    final controller = _animationControllers[id];
    if (controller == null) return;
    
    // Animate out
    controller.reverse().then((_) {
      if (mounted) {
        setState(() {
          _visibleNotifications.removeWhere((n) => n.id == id);
        });
        
        // Clean up animations
        _animationControllers.remove(id)?.dispose();
        _slideAnimations.remove(id);
        _fadeAnimations.remove(id);
      }
    });
    
    // Dismiss from service
    _notificationService.dismissNotification(id);
  }
  
  void _updateVisibleNotifications(List<NotificationItem> notifications) {
    if (!mounted) return;
    
    // Remove notifications that are no longer in the queue
    final currentIds = notifications.map((n) => n.id).toSet();
    final toRemove = _visibleNotifications
        .where((n) => !currentIds.contains(n.id))
        .toList();
    
    for (final notification in toRemove) {
      _dismissNotification(notification.id);
    }
  }
  
  Offset _getSlideBeginOffset() {
    switch (widget.alignment) {
      case Alignment.topLeft:
      case Alignment.centerLeft:
      case Alignment.bottomLeft:
        return const Offset(-1.0, 0.0);
      case Alignment.topRight:
      case Alignment.centerRight:
      case Alignment.bottomRight:
        return const Offset(1.0, 0.0);
      case Alignment.topCenter:
        return const Offset(0.0, -1.0);
      case Alignment.bottomCenter:
        return const Offset(0.0, 1.0);
      default:
        return const Offset(1.0, 0.0);
    }
  }
}

/// Notification queue widget for displaying all notifications
class NotificationQueueWidget extends StatelessWidget {
  final VoidCallback? onClearAll;
  
  const NotificationQueueWidget({
    super.key,
    this.onClearAll,
  });
  
  @override
  Widget build(BuildContext context) {
    final notificationService = Get.find<EnhancedNotificationService>();
    
    return StreamBuilder<List<NotificationItem>>(
      stream: notificationService.queueStream,
      initialData: notificationService.notifications,
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        
        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: Theme.of(context).disabledColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'no_notifications'.tr,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ],
            ),
          );
        }
        
        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'notifications'.tr,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (notifications.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        notificationService.dismissAll();
                        onClearAll?.call();
                      },
                      icon: const Icon(Icons.clear_all),
                      label: Text('clear_all'.tr),
                    ),
                ],
              ),
            ),
            
            // Notification list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _NotificationListItem(
                      notification: notification,
                      onDismiss: () => notificationService.dismissNotification(notification.id),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Individual notification list item
class _NotificationListItem extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onDismiss;
  
  const _NotificationListItem({
    required this.notification,
    required this.onDismiss,
  });
  
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: Card(
        child: ListTile(
          leading: Icon(
            _getNotificationIcon(notification.type),
            color: _getNotificationColor(notification.type),
          ),
          title: Text(
            notification.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.message),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(notification.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
              ),
            ],
          ),
          trailing: IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close),
          ),
          onTap: () {
            notification.onTap?.call();
            Get.find<EnhancedNotificationService>().markAsActioned(notification.id);
          },
        ),
      ),
    );
  }
  
  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Colors.green;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.info:
        return Colors.blue;
      case NotificationType.loading:
        return Colors.purple;
      case NotificationType.confirmation:
        return Colors.amber;
      case NotificationType.custom:
        return Colors.grey;
    }
  }
  
  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.info:
        return Icons.info;
      case NotificationType.loading:
        return Icons.hourglass_empty;
      case NotificationType.confirmation:
        return Icons.help;
      case NotificationType.custom:
        return Icons.notifications;
    }
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return 'just_now'.tr;
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}