// views/notification_fix_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/notification_controller.dart';
import '../utils/notification_cleanup.dart';

class NotificationFixScreen extends StatefulWidget {
  const NotificationFixScreen({super.key});

  @override
  State<NotificationFixScreen> createState() => _NotificationFixScreenState();
}

class _NotificationFixScreenState extends State<NotificationFixScreen> {
  final NotificationController notificationController = Get.find<NotificationController>();
  bool isFixing = false;
  String statusMessage = '';

  Future<void> _fixNotifications() async {
    setState(() {
      isFixing = true;
      statusMessage = 'Starting notification cleanup...';
    });

    try {
      setState(() {
        statusMessage = 'Deleting invalid notifications...';
      });
      
      await NotificationCleanup.deleteInvalidTaskAssignmentNotifications();
      
      setState(() {
        statusMessage = 'Creating missing notifications...';
      });
      
      await NotificationCleanup.createMissingTaskAssignmentNotifications();
      
      setState(() {
        statusMessage = 'Refreshing notification list...';
      });
      
      // Wait for changes to propagate
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Refresh notifications
      await notificationController.fetchNotifications();
      
      setState(() {
        statusMessage = 'Notification cleanup completed successfully!';
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications fixed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error fixing notifications: $e');
      setState(() {
        statusMessage = 'Error occurred during cleanup: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fixing notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isFixing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fix Notifications'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Fix Tool',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'If your task assignment notification count is showing 0 even though you have assigned tasks, use this tool to fix the issue.',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24.h),
            
            // Current notification counts
            Obx(() => Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Notification Counts',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text('Total Notifications: ${notificationController.totalNotifications.value}'),
                    Text('Unread Count: ${notificationController.unreadCount.value}'),
                    Text('Task Assignment Unread: ${notificationController.taskAssignmentUnreadCount.value}'),
                    Text('Valid Notifications: ${notificationController.validNotifications.length}'),
                  ],
                ),
              ),
            )),
            
            SizedBox(height: 24.h),
            
            // Fix button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isFixing ? null : _fixNotifications,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                ),
                child: isFixing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20.w,
                            height: 20.h,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          const Text('Fixing Notifications...'),
                        ],
                      )
                    : Text(
                        'Fix Notifications',
                        style: TextStyle(fontSize: 16.sp),
                      ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Status message
            if (statusMessage.isNotEmpty)
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Colors.blue,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          statusMessage,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            SizedBox(height: 24.h),
            
            // Instructions
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning,
                          color: Colors.orange,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Instructions',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '1. This tool will delete invalid notifications\n'
                      '2. Create new notifications for your assigned tasks\n'
                      '3. Refresh the notification counts\n'
                      '4. Go back to the home screen to see the updated counts',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.orange[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}