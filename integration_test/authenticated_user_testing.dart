// integration_test/authenticated_user_testing.dart
// Integration test for verifying permission guards work for authenticated users

import 'package:cloud_firestore/cloud_firestore.dart';
// Removed unnecessary import - firebase_auth elements are provided by cloud_firestore
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:get/get.dart';
import 'package:task/controllers/admin_controller.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:task/service/audit_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:task/firebase_options.dart';
import 'package:task/service/firebase_service.dart' show useFirebaseEmulator;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;

late String adminUid;
late String managerUid;
late String reporterUid;
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Dart-define controlled emulator usage for tests
  const bool testUseEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);
  const String testEmulatorHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST', defaultValue: 'localhost');

  group('Authenticated User Permission Testing', () {
    late AuthController authController;
    late AdminController adminController;
    late TaskController taskController;
    late AuditService auditService;

    setUpAll(() async {
      // Load environment for firebase_options
      await dotenv.load(fileName: 'assets/.env');
      // Initialize Firebase before any controllers that depend on it
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      if (testUseEmulator) {
        useFirebaseEmulator(testEmulatorHost);

        // Seed emulator with users and tasks used by tests via REST to avoid plugin network issues
        Future<String> ensureUser(String email, String password, String role) async {
          // Map localhost to Android emulator host if needed for REST calls
          String restHost = testEmulatorHost;
          if (Platform.isAndroid && (restHost == 'localhost' || restHost == '127.0.0.1')) {
            restHost = '10.0.2.2';
          }
          final signUpUrl = Uri.parse('http://$restHost:8002/identitytoolkit.googleapis.com/v1/accounts:signUp?key=dummy');
          final signInUrl = Uri.parse('http://$restHost:8002/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=dummy');

          // Try to sign up
          final signUpResp = await http.post(
            signUpUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password, 'returnSecureToken': true}),
          );

          Map<String, dynamic>? signUpJson;
          try { signUpJson = jsonDecode(signUpResp.body) as Map<String, dynamic>; } catch (_) {}

          String uid;
          if (signUpResp.statusCode == 200 && signUpJson != null && signUpJson['localId'] != null) {
            uid = signUpJson['localId'] as String;
          } else {
            // If already exists, sign in to get localId
            final signInResp = await http.post(
              signInUrl,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'email': email, 'password': password, 'returnSecureToken': true}),
            );
            if (signInResp.statusCode != 200) {
              throw Exception('Auth emulator signIn failed: ${signInResp.statusCode} ${signInResp.body}');
            }
            final signInJson = jsonDecode(signInResp.body) as Map<String, dynamic>;
            uid = signInJson['localId'] as String;
          }

          // Ensure Firestore profile exists with correct role
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'uid': uid,
            'email': email,
            'fullName': email.split('@').first.replaceAll('.', ' ').toUpperCase(),
            'role': role,
            'profileComplete': true,
            'photoUrl': '',
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          return uid;
        }

        const String adminEmail = 'admin.test@task.local';
        const String adminPassword = 'TestAdmin123!@#';
        const String managerEmail = 'manager.test@task.local';
        const String managerPassword = 'TestManager123!@#';
        const String reporterEmail = 'reporter.test@task.local';
        const String reporterPassword = 'TestReporter123!@#';

        adminUid = await ensureUser(adminEmail, adminPassword, 'Admin');
        managerUid = await ensureUser(managerEmail, managerPassword, 'Manager');
        reporterUid = await ensureUser(reporterEmail, reporterPassword, 'Reporter');

        final tasksRef = FirebaseFirestore.instance.collection('tasks');
        await tasksRef.doc('test-task-1').set({
          'title': 'Test Task 1',
          'description': 'Pending task to be approved',
          'createdBy': adminUid,
          'approvalStatus': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await tasksRef.doc('test-task-2').set({
          'title': 'Test Task 2',
          'description': 'Pending task to be rejected',
          'createdBy': adminUid,
          'approvalStatus': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await tasksRef.doc('test-task-3').set({
          'title': 'Test Task 3',
          'description': 'Task to be assigned',
          'createdBy': adminUid,
          'approvalStatus': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });

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
        final userId = reporterUid;

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

    group('Legacy Task Creator Permissions', () {
      test('Non-admin creator of legacy task can update status/content', () async {
        // Arrange: sign in as Reporter (non-admin)
        await authController.signIn('reporter.test@task.local', 'TestReporter123!@#');
        final uid = authController.currentUser!.uid;

        // Create a legacy-style task document (createdById only, no createdBy)
        final ref = await FirebaseFirestore.instance.collection('tasks').add({
          'title': 'Legacy Task',
          'description': 'Initial',
          'status': 'pending',
          'createdById': uid,
        });

        // Act: attempt to update status and content (should be allowed for creator)
        await FirebaseFirestore.instance.collection('tasks').doc(ref.id).update({
          'status': 'in_progress',
          'title': 'Updated Legacy Task',
          'description': 'Updated content',
        });

        // Assert
        final doc = await ref.get();
        expect(doc.get('status'), equals('in_progress'));
        expect(doc.get('title'), equals('Updated Legacy Task'));
        expect(doc.get('description'), equals('Updated content'));
      });

      test('Non-admin legacy creator can delete their task', () async {
        // Arrange: sign in as Reporter (non-admin)
        await authController.signIn('reporter.test@task.local', 'TestReporter123!@#');
        final uid = authController.currentUser!.uid;

        // Create a legacy-style task document
        final ref = await FirebaseFirestore.instance.collection('tasks').add({
          'title': 'Legacy Task To Delete',
          'status': 'pending',
          'createdById': uid,
        });

        // Act: delete the task (should be allowed)
        await FirebaseFirestore.instance.collection('tasks').doc(ref.id).delete();

        // Assert: verify deletion
        final deletedDoc = await FirebaseFirestore.instance.collection('tasks').doc(ref.id).get();
        expect(deletedDoc.exists, isFalse);
      });

      test('Non-admin cannot update approval fields', () async {
        // Arrange: sign in as Reporter (non-admin)
        await authController.signIn('reporter.test@task.local', 'TestReporter123!@#');
        final uid = authController.currentUser!.uid;
        final ref = await FirebaseFirestore.instance.collection('tasks').add({
          'title': 'Approval Restricted Task',
          'status': 'pending',
          'createdById': uid,
        });

        // Act & Assert: approval update should be blocked by rules
        expect(
          () async {
            await FirebaseFirestore.instance.collection('tasks').doc(ref.id).update({
              'approvalStatus': 'approved',
              'approvedBy': uid,
              'approvalTimestamp': DateTime.now().millisecondsSinceEpoch,
            });
          },
          throwsA(isA<FirebaseException>()),
        );
      });

      test('Non-admin cannot perform assignment updates', () async {
        // Arrange: sign in as Reporter (non-admin)
        await authController.signIn('reporter.test@task.local', 'TestReporter123!@#');
        final uid = authController.currentUser!.uid;
        final ref = await FirebaseFirestore.instance.collection('tasks').add({
          'title': 'Assignment Restricted Task',
          'status': 'pending',
          'createdById': uid,
        });

        // Act & Assert: assignment update should be blocked by rules
        expect(
          () async {
            await FirebaseFirestore.instance.collection('tasks').doc(ref.id).update({
              'assignedReporterId': 'user-123',
              'assignedReporter': 'John Doe',
              'assignmentTimestamp': DateTime.now().millisecondsSinceEpoch,
            });
          },
          throwsA(isA<FirebaseException>()),
        );
      });
    });

    group('Admin Delete Behavior', () {
      test('Admin can permanently delete any task', () async {
        // Arrange: create a task as Reporter
        await authController.signIn('reporter.test@task.local', 'TestReporter123!@#');
        final reporterUid = authController.currentUser!.uid;
        final ref = await FirebaseFirestore.instance.collection('tasks').add({
          'title': 'Task To Be Deleted By Admin',
          'status': 'pending',
          'createdById': reporterUid,
        });

        // Switch to admin
        await authController.signIn('admin.test@task.local', 'TestAdmin123!@#');
        expect(authController.isAdmin.value, isTrue);

        // Act: delete the task as admin
        await FirebaseFirestore.instance.collection('tasks').doc(ref.id).delete();

        // Assert: verify deletion
        final deletedDoc = await FirebaseFirestore.instance.collection('tasks').doc(ref.id).get();
        expect(deletedDoc.exists, isFalse);
      });
    });
  });
}
