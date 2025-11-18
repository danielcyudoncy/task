// test/authenticated_user_testing.dart
// Integration test for verifying permission guards work for authenticated users

import 'package:cloud_firestore/cloud_firestore.dart';
// Removed unnecessary import - firebase_auth elements are provided by cloud_firestore
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:task/controllers/admin_controller.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:task/service/audit_service.dart';

void main() {
  group('Authenticated User Permission Testing', () {
    late AuthController authController;
    late AdminController adminController;
    late TaskController taskController;
    late AuditService auditService;

    setUp(() {
      // Initialize controllers
      Get.put(AuthController());
      Get.put(AdminController());
      Get.put(TaskController());

      authController = Get.find<AuthController>();
      adminController = Get.find<AdminController>();
      taskController = Get.find<TaskController>();
      auditService = AuditService();
    });

    tearDown(() {
      Get.reset();
    });

    group('Phase 1: Admin User Tests', () {
      test('Admin user can login successfully', () async {
        // Arrange
        final email = 'admin.test@task.local';
        final password = 'TestAdmin123!@#';

        // Act
        await authController.signIn(email, password);

        // Assert
        expect(authController.currentUser, isNotNull);
        expect(authController.userRole.value, equals('Admin'));
        expect(authController.isAdmin.value, isTrue);
      });

      test('Admin user sees all dashboard data', () async {
        // Arrange
        final email = 'admin.test@task.local';
        final password = 'TestAdmin123!@#';

        // Act
        await authController.signIn(email, password);
        await adminController.fetchAdminProfile();

        // Assert
        expect(adminController.totalUsers.value, greaterThanOrEqualTo(0));
        expect(adminController.totalTasks.value, greaterThanOrEqualTo(0));
        expect(adminController.adminEmail.value, equals(email));
      });

      test('Admin can approve a pending task', () async {
        // Arrange
        await authController.signIn('admin.test@task.local', 'TestAdmin123!@#');
        final taskId = 'test-task-1'; // Would fetch from Firestore in real test

        // Act
        try {
          await taskController.approveTask(taskId);

          // Assert
          final taskDoc = await FirebaseFirestore.instance
              .collection('tasks')
              .doc(taskId)
              .get();

          expect(taskDoc.get('approvalStatus'), equals('approved'));
          expect(taskDoc.get('approvedBy'), isNotNull);

          // Verify audit log was created
          final auditLogs = await FirebaseFirestore.instance
              .collection('audit_logs')
              .where('resourceId', isEqualTo: taskId)
              .where('operationType', isEqualTo: 'task_approved')
              .get();

          expect(auditLogs.docs, isNotEmpty);
        } catch (e) {
          fail('Admin task approval failed: $e');
        }
      });

      test('Admin can reject a pending task', () async {
        // Arrange
        await authController.signIn('admin.test@task.local', 'TestAdmin123!@#');
        final taskId = 'test-task-2';

        // Act
        try {
          await taskController.rejectTask(taskId, reason: 'Rejection reason');

          // Assert
          final taskDoc = await FirebaseFirestore.instance
              .collection('tasks')
              .doc(taskId)
              .get();

          expect(taskDoc.get('approvalStatus'), equals('rejected'));

          // Verify audit log was created
          final auditLogs = await FirebaseFirestore.instance
              .collection('audit_logs')
              .where('resourceId', isEqualTo: taskId)
              .where('operationType', isEqualTo: 'task_rejected')
              .get();

          expect(auditLogs.docs, isNotEmpty);
        } catch (e) {
          fail('Admin task rejection failed: $e');
        }
      });

      test('Admin can assign task to user', () async {
        // Arrange
        await authController.signIn('admin.test@task.local', 'TestAdmin123!@#');
        final taskId = 'test-task-3';
        final userId = 'test-user-reporter';

        // Act
        try {
          await adminController.assignTaskToUser(
            userId: userId,
            assignedName: 'Test User',
            taskTitle: 'Test Task',
            taskDescription: 'Test Description',
            dueDate: DateTime.now(),
            taskId: taskId,
          );

          // Assert
          final taskDoc = await FirebaseFirestore.instance
              .collection('tasks')
              .doc(taskId)
              .get();

          expect(taskDoc.get('assignedTo'), isNotNull);

          // Verify audit log was created
          final auditLogs = await FirebaseFirestore.instance
              .collection('audit_logs')
              .where('resourceId', isEqualTo: taskId)
              .where('operationType', isEqualTo: 'task_assigned')
              .get();

          expect(auditLogs.docs, isNotEmpty);
        } catch (e) {
          fail('Admin task assignment failed: $e');
        }
      });

      test('Admin audit logs are immutable', () async {
        // Arrange
        await authController.signIn('admin.test@task.local', 'TestAdmin123!@#');

        // Get a recent audit log
        final auditLogs = await FirebaseFirestore.instance
            .collection('audit_logs')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        if (auditLogs.docs.isEmpty) {
          return; // Skip if no audit logs
        }

        final auditLogId = auditLogs.docs.first.id;

        // Act & Assert - Try to update (should fail)
        expect(
          () async {
            await FirebaseFirestore.instance
                .collection('audit_logs')
                .doc(auditLogId)
                .update({'operationType': 'hacked'});
          },
          throwsA(isA<FirebaseException>()),
        );
      });
    });

    group('Phase 2: Manager User Tests', () {
      test('Manager user can login successfully', () async {
        // Arrange
        final email = 'manager.test@task.local';
        final password = 'TestManager123!@#';

        // Act
        await authController.signIn(email, password);

        // Assert
        expect(authController.currentUser, isNotNull);
        expect(authController.userRole.value, equals('Manager'));
      });

      test('Manager cannot approve tasks', () async {
        // Arrange
        await authController.signIn(
            'manager.test@task.local', 'TestManager123!@#');
        final taskId = 'test-task-1';

        // Act & Assert
        expect(
          () async {
            await taskController.approveTask(taskId);
          },
          throwsA(isA<Exception>()),
        );
      });

      test('Manager cannot reject tasks', () async {
        // Arrange
        await authController.signIn(
            'manager.test@task.local', 'TestManager123!@#');
        final taskId = 'test-task-1';

        // Act & Assert
        expect(
          () async {
            await taskController.rejectTask(taskId, reason: 'reason');
          },
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Phase 3: Reporter User Tests', () {
      test('Reporter user can login successfully', () async {
        // Arrange
        final email = 'reporter.test@task.local';
        final password = 'TestReporter123!@#';

        // Act
        await authController.signIn(email, password);

        // Assert
        expect(authController.currentUser, isNotNull);
        expect(authController.userRole.value, equals('Reporter'));
        expect(authController.isAdmin.value, isFalse);
      });

      test('Reporter cannot approve tasks', () async {
        // Arrange
        await authController.signIn(
            'reporter.test@task.local', 'TestReporter123!@#');
        final taskId = 'test-task-1';

        // Act & Assert
        expect(
          () async {
            await taskController.approveTask(taskId);
          },
          throwsA(isA<Exception>()),
        );
      });

      test('Reporter cannot access admin dashboard', () async {
        // Arrange
        await authController.signIn(
            'reporter.test@task.local', 'TestReporter123!@#');

        // Act & Assert
        expect(
          () async {
            await adminController.fetchAdminProfile();
          },
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Firestore Rules Enforcement', () {
      test('Unauthenticated users cannot read tasks', () async {
        // Act & Assert
        expect(
          () async {
            await FirebaseFirestore.instance.collection('tasks').get();
          },
          throwsA(isA<FirebaseException>()),
        );
      });

      test('Unauthenticated users cannot create tasks', () async {
        // Act & Assert
        expect(
          () async {
            await FirebaseFirestore.instance.collection('tasks').add({
              'title': 'Unauthorized task',
              'createdBy': 'hacker',
            });
          },
          throwsA(isA<FirebaseException>()),
        );
      });

      test('Audit logs cannot be deleted', () async {
        // Arrange
        await authController.signIn('admin.test@task.local', 'TestAdmin123!@#');

        final auditLogs = await FirebaseFirestore.instance
            .collection('audit_logs')
            .limit(1)
            .get();

        if (auditLogs.docs.isEmpty) {
          return; // Skip if no logs
        }

        // Act & Assert
        expect(
          () async {
            await FirebaseFirestore.instance
                .collection('audit_logs')
                .doc(auditLogs.docs.first.id)
                .delete();
          },
          throwsA(isA<FirebaseException>()),
        );
      });
    });

    group('Audit Service Integration', () {
      test('Audit service logs admin operations', () async {
        // Arrange
        await authController.signIn('admin.test@task.local', 'TestAdmin123!@#');
        final taskId = 'test-task-audit';

        // Act
        await auditService.logTaskApproval(
          taskId: taskId,
          taskTitle: 'Test Task',
          reason: 'Test approval',
        );

        // Assert
        final logs = await auditService.getAuditLogsForResource(
          resourceId: taskId,
        );
        expect(logs, isNotEmpty);
        expect(logs.first['resourceId'], equals(taskId));
      });

      test('Audit service creates immutable records', () async {
        // Arrange
        await authController.signIn('admin.test@task.local', 'TestAdmin123!@#');

        final auditLogs = await FirebaseFirestore.instance
            .collection('audit_logs')
            .limit(1)
            .get();

        if (auditLogs.docs.isEmpty) {
          return;
        }

        final logId = auditLogs.docs.first.id;
        final originalData = auditLogs.docs.first.data();

        // Act & Assert - Verify cannot be modified
        expect(
          () async {
            await FirebaseFirestore.instance
                .collection('audit_logs')
                .doc(logId)
                .update({'tampered': true});
          },
          throwsA(isA<FirebaseException>()),
        );

        // Verify data unchanged
        final refreshedDoc = await FirebaseFirestore.instance
            .collection('audit_logs')
            .doc(logId)
            .get();

        expect(refreshedDoc.data(), equals(originalData));
      });
    });

    group('Permission Guard Validation', () {
      test('Permission guard blocks non-admin from task approval', () async {
        // Arrange
        await authController.signIn(
            'reporter.test@task.local', 'TestReporter123!@#');

        // Act & Assert
        expect(authController.isAdmin.value, isFalse);
        expect(authController.userRole.value, equals('Reporter'));

        // Try to approve (should throw or be blocked)
        expect(
          () async {
            await taskController.approveTask('some-task-id');
          },
          throwsA(isA<Exception>()),
        );
      });

      test('Permission guard allows admin task approval', () async {
        // Arrange
        await authController.signIn('admin.test@task.local', 'TestAdmin123!@#');

        // Act & Assert
        expect(authController.isAdmin.value, isTrue);
        expect(authController.userRole.value, equals('Admin'));

        // Admin should be able to attempt approval
        // (may fail due to task status, but not due to permissions)
        // This is just verifying the permission check passes
        try {
          await taskController.approveTask('nonexistent-task');
        } catch (e) {
          // Expected to fail if task doesn't exist, but not due to permissions
          expect(e.toString(), isNot(contains('permission')));
        }
      });
    });
  });
}
