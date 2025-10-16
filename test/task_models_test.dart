// test/task_models_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:task/models/task.dart';
import 'package:task/models/task_core.dart';
import 'package:task/models/task_metadata.dart';

void main() {
  group('Task Models', () {
    group('TaskCore', () {
      test('should create TaskCore with valid data', () {
        final core = TaskCore(
          taskId: 'test-id',
          title: 'Test Task',
          description: 'Test Description',
          createdBy: 'user1',
          createdById: 'user1',
          status: 'Pending',
          timestamp: DateTime.now(),
        );

        expect(core.taskId, equals('test-id'));
        expect(core.title, equals('Test Task'));
        expect(core.isPending, isTrue);
        expect(core.isCompleted, isFalse);
      });

      test('should parse TaskCore from map correctly', () {
        final map = {
          'taskId': 'test-id',
          'title': 'Test Task',
          'description': 'Test Description',
          'createdBy': 'user1',
          'createdById': 'user1',
          'status': 'Completed',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        final core = TaskCore.fromMap(map);

        expect(core.taskId, equals('test-id'));
        expect(core.title, equals('Test Task'));
        expect(core.isCompleted, isTrue);
        expect(core.isPending, isFalse);
      });
    });

    group('TaskMetadata', () {
      test('should create TaskMetadata with valid data', () {
        final metadata = TaskMetadata(
          approvalStatus: 'approved',
          comments: ['Test comment'],
          attachmentUrls: ['https://example.com/file.pdf'],
        );

        expect(metadata.isApproved, isTrue);
        expect(metadata.comments, hasLength(1));
        expect(metadata.attachmentUrls, hasLength(1));
      });

      test('should parse TaskMetadata from map correctly', () {
        final map = {
          'approvalStatus': 'approved',
          'comments': '["Comment 1", "Comment 2"]',
          'attachmentUrls': '["https://example.com/file1.pdf"]',
        };

        final metadata = TaskMetadata.fromMap(map);

        expect(metadata.isApproved, isTrue);
        expect(metadata.comments, hasLength(2));
        expect(metadata.attachmentUrls, hasLength(1));
      });
    });

    group('Task (Combined)', () {
      test('should create Task with core and metadata', () {
        final core = TaskCore(
          taskId: 'test-id',
          title: 'Test Task',
          description: 'Test Description',
          createdBy: 'user1',
          createdById: 'user1',
          status: 'Pending',
          timestamp: DateTime.now(),
        );

        final metadata = TaskMetadata(
          approvalStatus: 'approved',
          comments: ['Test comment'],
        );

        final task = Task(core: core, metadata: metadata);

        expect(task.taskId, equals('test-id'));
        expect(task.title, equals('Test Task'));
        expect(task.isPending, isTrue);
        expect(task.isApproved, isTrue);
        expect(task.comments, hasLength(1));
      });

      test('should handle Task without metadata', () {
        final core = TaskCore(
          taskId: 'test-id',
          title: 'Test Task',
          description: 'Test Description',
          createdBy: 'user1',
          createdById: 'user1',
          status: 'Pending',
          timestamp: DateTime.now(),
        );

        final task = Task(core: core);

        expect(task.taskId, equals('test-id'));
        expect(task.isApproved, isFalse); // Default when no metadata
        expect(task.comments, isEmpty);
      });

      test('should parse Task from map correctly', () {
        final map = {
          'taskId': 'test-id',
          'title': 'Test Task',
          'description': 'Test Description',
          'createdBy': 'user1',
          'createdById': 'user1',
          'status': 'Pending',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'approvalStatus': 'approved',
          'comments': '["Test comment"]',
        };

        final task = Task.fromMap(map);

        expect(task.taskId, equals('test-id'));
        expect(task.title, equals('Test Task'));
        expect(task.isPending, isTrue);
        expect(task.isApproved, isTrue);
        expect(task.comments, hasLength(1));
      });
    });

    group('Task Business Logic', () {
      test('should correctly identify overdue tasks', () {
        final overdueDate = DateTime.now().subtract(const Duration(days: 1));
        final core = TaskCore(
          taskId: 'overdue-task',
          title: 'Overdue Task',
          description: 'This task is overdue',
          createdBy: 'user1',
          createdById: 'user1',
          status: 'Pending',
          timestamp: DateTime.now(),
          dueDate: overdueDate,
        );

        expect(core.isOverdue, isTrue);
      });

      test('should not mark completed tasks as overdue', () {
        final pastDate = DateTime.now().subtract(const Duration(days: 1));
        final core = TaskCore(
          taskId: 'completed-task',
          title: 'Completed Task',
          description: 'This task is completed',
          createdBy: 'user1',
          createdById: 'user1',
          status: 'Completed',
          timestamp: DateTime.now(),
          dueDate: pastDate,
        );

        expect(core.isOverdue, isFalse);
      });

      test('should handle task assignment correctly', () {
        final metadata = TaskMetadata(
          assignedReporterId: 'reporter1',
          assignedCameramanId: 'cameraman1',
          assignedDriverId: 'driver1',
        );

        expect(metadata.assignedUserIds, hasLength(3));
        expect(metadata.assignedUserIds, contains('reporter1'));
        expect(metadata.assignedUserIds, contains('cameraman1'));
        expect(metadata.assignedUserIds, contains('driver1'));
      });
    });
  });
}