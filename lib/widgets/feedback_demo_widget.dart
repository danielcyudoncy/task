// widgets/feedback_demo_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../service/enhanced_notification_service.dart';

/// Demo widget showcasing the enhanced notification system
class FeedbackDemoWidget extends StatefulWidget {
  const FeedbackDemoWidget({super.key});

  @override
  State<FeedbackDemoWidget> createState() => _FeedbackDemoWidgetState();
}

class _FeedbackDemoWidgetState extends State<FeedbackDemoWidget> {
  final EnhancedNotificationService _notificationService =
      Get.find<EnhancedNotificationService>();

  double _loadingProgress = 0.0;
  String? _currentLoadingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('notification_demo'.tr),
        actions: [
          IconButton(
            onPressed: _showNotificationQueue,
            icon: StreamBuilder<List<NotificationItem>>(
              stream: _notificationService.queueStream,
              initialData: _notificationService.notifications,
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return Badge(
                  label: Text(count.toString()),
                  isLabelVisible: count > 0,
                  child: const Icon(Icons.notifications),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Basic notifications section
            _buildSection(
              title: 'basic_notifications'.tr,
              children: [
                _buildNotificationButton(
                  label: 'success_notification'.tr,
                  color: Colors.green,
                  icon: Icons.check_circle,
                  onPressed: () => _showSuccessNotification(),
                ),
                _buildNotificationButton(
                  label: 'error_notification'.tr,
                  color: Colors.red,
                  icon: Icons.error,
                  onPressed: () => _showErrorNotification(),
                ),
                _buildNotificationButton(
                  label: 'warning_notification'.tr,
                  color: Colors.orange,
                  icon: Icons.warning,
                  onPressed: () => _showWarningNotification(),
                ),
                _buildNotificationButton(
                  label: 'info_notification'.tr,
                  color: Colors.blue,
                  icon: Icons.info,
                  onPressed: () => _showInfoNotification(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Interactive notifications section
            _buildSection(
              title: 'interactive_notifications'.tr,
              children: [
                _buildNotificationButton(
                  label: 'loading_notification'.tr,
                  color: Colors.purple,
                  icon: Icons.hourglass_empty,
                  onPressed: () => _showLoadingNotification(),
                ),
                _buildNotificationButton(
                  label: 'confirmation_dialog'.tr,
                  color: Colors.amber,
                  icon: Icons.help,
                  onPressed: () => _showConfirmationNotification(),
                ),
                _buildNotificationButton(
                  label: 'action_notification'.tr,
                  color: Colors.indigo,
                  icon: Icons.touch_app,
                  onPressed: () => _showActionNotification(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Batch operations section
            _buildSection(
              title: 'batch_operations'.tr,
              children: [
                _buildNotificationButton(
                  label: 'multiple_notifications'.tr,
                  color: Colors.teal,
                  icon: Icons.queue,
                  onPressed: () => _showMultipleNotifications(),
                ),
                _buildNotificationButton(
                  label: 'clear_all_notifications'.tr,
                  color: Colors.grey,
                  icon: Icons.clear_all,
                  onPressed: () => _notificationService.dismissAll(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Statistics section
            _buildSection(
              title: 'notification_statistics'.tr,
              children: [
                _buildStatisticsCard(_getStatistics()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(Map<String, dynamic> stats) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    label: 'total_sent'.tr,
                    value: (stats['total_notifications'] ?? 0).toString(),
                    icon: Icons.send,
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    label: 'total_dismissed'.tr,
                    value: (stats['dismissed_notifications'] ?? 0).toString(),
                    icon: Icons.close,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    label: 'total_actioned'.tr,
                    value: (stats['actioned_notifications'] ?? 0).toString(),
                    icon: Icons.touch_app,
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    label: 'queue_size'.tr,
                    value: (stats['active_notifications'] ?? 0).toString(),
                    icon: Icons.queue,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Notification methods

  void _showSuccessNotification() {
    _notificationService.showSuccess(
      title: 'success'.tr,
      message: 'task_completed_successfully'.tr,
      duration: const Duration(seconds: 3),
    );
  }

  void _showErrorNotification() {
    _notificationService.showError(
      title: 'error_occurred'.tr,
      message: 'failed_to_save_task'.tr,
      actions: [
        NotificationAction(
          label: 'retry'.tr,
          onPressed: () {
            _notificationService.showInfo(
              title: 'retrying'.tr,
              message: 'attempting_to_save_again'.tr,
            );
          },
          isPrimary: true,
        ),
        NotificationAction(
          label: 'cancel'.tr,
          onPressed: () {},
        ),
      ],
    );
  }

  void _showWarningNotification() {
    _notificationService.showWarning(
      title: 'warning'.tr,
      message: 'unsaved_changes_detected'.tr,
      actions: [
        NotificationAction(
          label: 'save_now'.tr,
          onPressed: () {
            _notificationService.showSuccess(
              title: 'saved'.tr,
              message: 'changes_saved_successfully'.tr,
            );
          },
          isPrimary: true,
        ),
        NotificationAction(
          label: 'discard'.tr,
          onPressed: () {},
          isDestructive: true,
        ),
      ],
    );
  }

  void _showInfoNotification() {
    _notificationService.showInfo(
      title: 'tip'.tr,
      message: 'you_can_drag_tasks_to_reorder'.tr,
      duration: const Duration(seconds: 5),
    );
  }

  void _showLoadingNotification() {
    _loadingProgress = 0.0;

    _currentLoadingId = _notificationService.showLoading(
      title: 'syncing_data'.tr,
      message: 'please_wait_while_syncing'.tr,
    );

    // Simulate progress
    _simulateProgress();
  }

  void _showConfirmationNotification() async {
    final confirmed = await _notificationService.showConfirmation(
      title: 'delete_task'.tr,
      message: 'are_you_sure_delete_task'.tr,
    );

    if (confirmed) {
      _notificationService.showSuccess(
        title: 'deleted'.tr,
        message: 'task_deleted_successfully'.tr,
      );
    } else {
      _notificationService.showInfo(
        title: 'cancelled'.tr,
        message: 'deletion_cancelled'.tr,
      );
    }
  }

  void _showActionNotification() {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: NotificationType.info,
      title: 'new_feature_available'.tr,
      message: 'check_out_new_task_templates'.tr,
      actions: [
        NotificationAction(
          label: 'explore_now'.tr,
          icon: Icons.explore,
          onPressed: () {
            _notificationService.showSuccess(
              title: 'exploring'.tr,
              message: 'opening_task_templates'.tr,
            );
          },
          isPrimary: true,
        ),
        NotificationAction(
          label: 'remind_later'.tr,
          icon: Icons.schedule,
          onPressed: () {
            _notificationService.showInfo(
              title: 'reminder_set'.tr,
              message: 'will_remind_you_tomorrow'.tr,
            );
          },
        ),
        NotificationAction(
          label: 'dont_show_again'.tr,
          onPressed: () {},
        ),
      ],
      duration: const Duration(seconds: 10),
      timestamp: DateTime.now(),
    );

    _notificationService.showCustom(notification);
  }

  void _showMultipleNotifications() {
    final notifications = [
      () => _notificationService.showInfo(
            title: 'step_1'.tr,
            message: 'preparing_data'.tr,
          ),
      () => _notificationService.showInfo(
            title: 'step_2'.tr,
            message: 'validating_input'.tr,
          ),
      () => _notificationService.showWarning(
            title: 'step_3'.tr,
            message: 'found_potential_issues'.tr,
          ),
      () => _notificationService.showSuccess(
            title: 'completed'.tr,
            message: 'all_steps_completed'.tr,
          ),
    ];

    for (int i = 0; i < notifications.length; i++) {
      Future.delayed(Duration(milliseconds: i * 500), notifications[i]);
    }
  }

  void _showNotificationQueue() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: _buildNotificationQueue(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatistics() {
    return _notificationService.getStatistics();
  }

  Widget _buildNotificationQueue() {
    return StreamBuilder<List<NotificationItem>>(
      stream: _notificationService.queueStream,
      initialData: _notificationService.notifications,
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
                        _notificationService.dismissAll();
                        Navigator.of(context).pop();
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
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
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
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).disabledColor,
                                    ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        onPressed: () => _notificationService
                            .dismissNotification(notification.id),
                        icon: const Icon(Icons.close),
                      ),
                      onTap: () {
                        notification.onTap?.call();
                        _notificationService.markAsActioned(notification.id);
                      },
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

  void _simulateProgress() {
    if (_currentLoadingId == null) return;

    const duration = Duration(milliseconds: 100);
    const increment = 0.05;

    Future.delayed(duration, () {
      if (_loadingProgress < 1.0 && _currentLoadingId != null) {
        _loadingProgress += increment;

        _notificationService.updateLoading(
          _currentLoadingId!,
          progress: _loadingProgress,
        );

        if (_loadingProgress < 1.0) {
          _simulateProgress();
        } else {
          // Complete loading
          _notificationService.dismissNotification(_currentLoadingId!);
          _notificationService.showSuccess(
            title: 'sync_completed'.tr,
            message: 'data_synced_successfully'.tr,
          );
          _currentLoadingId = null;
        }
      }
    });
  }
}

/// Import the NotificationQueueWidget from notification_overlay.dart
/// This is already defined in that file, so we just need to import it
