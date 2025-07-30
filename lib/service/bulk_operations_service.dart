// service/bulk_operations_service.dart
import 'package:get/get.dart';
import 'package:task/models/task_model.dart';
import 'package:task/service/archive_service.dart';
import 'package:task/service/export_service.dart';
import 'package:task/service/pdf_export_service.dart';
import 'package:task/controllers/task_controller.dart';

class BulkOperationsService extends GetxService {
  static BulkOperationsService get to => Get.find();
  
  final ArchiveService _archiveService;
  final ExportService _exportService;
  final PdfExportService _pdfExportService;
  final TaskController _taskController;
  bool _isInitialized = false;
  
  BulkOperationsService({
    ArchiveService? archiveService,
    ExportService? exportService,
    PdfExportService? pdfExportService,
    TaskController? taskController,
  }) : _archiveService = archiveService ?? Get.find<ArchiveService>(),
       _exportService = exportService ?? Get.find<ExportService>(),
       _pdfExportService = pdfExportService ?? Get.find<PdfExportService>(),
       _taskController = taskController ?? Get.find<TaskController>();

  /// Initializes the bulk operations service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      Get.log('BulkOperationsService: Initializing...');
      _isInitialized = true;
      Get.log('BulkOperationsService: Initialized successfully');
    } catch (e) {
      Get.log('BulkOperationsService: Initialization failed: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Bulk archive tasks
  Future<BulkOperationResult> bulkArchiveTasks({
    required List<String> taskIds,
    required String reason,
    String? location,
    Function(int current, int total)? onProgress,
  }) async {
    if (!_isInitialized) {
      throw Exception('BulkOperationsService not initialized');
    }

    final result = BulkOperationResult();
    
    try {
      Get.log('Starting bulk archive operation for ${taskIds.length} tasks');
      
      for (int i = 0; i < taskIds.length; i++) {
        final taskId = taskIds[i];
        onProgress?.call(i + 1, taskIds.length);
        
        try {
          await _archiveService.archiveTask(
            taskId: taskId,
            reason: reason,
            location: location,
          );
          result.successfulOperations.add(taskId);
          Get.log('Successfully archived task: $taskId');
        } catch (e) {
          result.failedOperations[taskId] = e.toString();
          Get.log('Failed to archive task $taskId: $e');
        }
      }
      
      Get.log('Bulk archive completed: ${result.successfulOperations.length} successful, ${result.failedOperations.length} failed');
      return result;
    } catch (e) {
      Get.log('Bulk archive operation failed: $e');
      rethrow;
    }
  }

  /// Bulk unarchive tasks
  Future<BulkOperationResult> bulkUnarchiveTasks({
    required List<String> taskIds,
    Function(int current, int total)? onProgress,
  }) async {
    if (!_isInitialized) {
      throw Exception('BulkOperationsService not initialized');
    }

    final result = BulkOperationResult();
    
    try {
      Get.log('Starting bulk unarchive operation for ${taskIds.length} tasks');
      
      for (int i = 0; i < taskIds.length; i++) {
        final taskId = taskIds[i];
        onProgress?.call(i + 1, taskIds.length);
        
        try {
          await _archiveService.unarchiveTask(taskId);
          result.successfulOperations.add(taskId);
          Get.log('Successfully unarchived task: $taskId');
        } catch (e) {
          result.failedOperations[taskId] = e.toString();
          Get.log('Failed to unarchive task $taskId: $e');
        }
      }
      
      Get.log('Bulk unarchive completed: ${result.successfulOperations.length} successful, ${result.failedOperations.length} failed');
      return result;
    } catch (e) {
      Get.log('Bulk unarchive operation failed: $e');
      rethrow;
    }
  }

  /// Bulk export tasks to CSV
  Future<BulkExportResult> bulkExportTasksToCSV({
    required List<Task> tasks,
    String? fileName,
    Function(int current, int total)? onProgress,
  }) async {
    if (!_isInitialized) {
      throw Exception('BulkOperationsService not initialized');
    }

    try {
      Get.log('Starting bulk CSV export for ${tasks.length} tasks');
      onProgress?.call(1, 1); // CSV export is atomic
      
      final filePath = await _exportService.exportTasksToCSV(
        tasks,
      );
      
      Get.log('Bulk CSV export completed successfully');
      return BulkExportResult(
        success: true,
        filePath: filePath,
        exportedCount: tasks.length,
      );
    } catch (e) {
      Get.log('Bulk CSV export failed: $e');
      return BulkExportResult(
        success: false,
        error: e.toString(),
        exportedCount: 0,
      );
    }
  }

  /// Bulk export tasks to PDF
  Future<BulkExportResult> bulkExportTasksToPDF({
    required List<Task> tasks,
    String? title,
    Function(int current, int total)? onProgress,
  }) async {
    if (!_isInitialized) {
      throw Exception('BulkOperationsService not initialized');
    }

    try {
      Get.log('Starting bulk PDF export for ${tasks.length} tasks');
      onProgress?.call(1, 1); // PDF export is atomic
      
      final filePath = await _pdfExportService.exportTasksToPdf(
        tasks,
        title: title,
      );
      
      Get.log('Bulk PDF export completed successfully');
      return BulkExportResult(
        success: true,
        filePath: filePath,
        exportedCount: tasks.length,
      );
    } catch (e) {
      Get.log('Bulk PDF export failed: $e');
      return BulkExportResult(
        success: false,
        error: e.toString(),
        exportedCount: 0,
      );
    }
  }

  /// Bulk update task status
  Future<BulkOperationResult> bulkUpdateTaskStatus({
    required List<String> taskIds,
    required String newStatus,
    Function(int current, int total)? onProgress,
  }) async {
    if (!_isInitialized) {
      throw Exception('BulkOperationsService not initialized');
    }

    final result = BulkOperationResult();
    
    try {
      Get.log('Starting bulk status update for ${taskIds.length} tasks to status: $newStatus');
      
      for (int i = 0; i < taskIds.length; i++) {
        final taskId = taskIds[i];
        onProgress?.call(i + 1, taskIds.length);
        
        try {
          await _taskController.updateTaskStatus(taskId, newStatus);
          result.successfulOperations.add(taskId);
          Get.log('Successfully updated status for task: $taskId');
        } catch (e) {
          result.failedOperations[taskId] = e.toString();
          Get.log('Failed to update status for task $taskId: $e');
        }
      }
      
      Get.log('Bulk status update completed: ${result.successfulOperations.length} successful, ${result.failedOperations.length} failed');
      return result;
    } catch (e) {
      Get.log('Bulk status update operation failed: $e');
      rethrow;
    }
  }

  /// Bulk assign tasks to user
  Future<BulkOperationResult> bulkAssignTasks({
    required List<String> taskIds,
    required String userId,
    required String role, // 'reporter', 'cameraman', 'driver', 'librarian'
    Function(int current, int total)? onProgress,
  }) async {
    if (!_isInitialized) {
      throw Exception('BulkOperationsService not initialized');
    }

    final result = BulkOperationResult();
    
    try {
      Get.log('Starting bulk assignment for ${taskIds.length} tasks to user: $userId as $role');
      
      for (int i = 0; i < taskIds.length; i++) {
        final taskId = taskIds[i];
        onProgress?.call(i + 1, taskIds.length);
        
        try {
          // Get the current task
          final task = await _taskController.getTaskById(taskId);
          if (task == null) {
            throw Exception('Task not found');
          }
          
          // Create updated task with new assignment
          Task updatedTask;
          switch (role.toLowerCase()) {
            case 'reporter':
              updatedTask = task.copyWith(assignedReporter: userId);
              break;
            case 'cameraman':
              updatedTask = task.copyWith(assignedCameraman: userId);
              break;
            case 'driver':
              updatedTask = task.copyWith(assignedDriver: userId);
              break;
            case 'librarian':
              updatedTask = task.copyWith(assignedLibrarian: userId);
              break;
            default:
              throw Exception('Invalid role: $role');
          }
          
          await _taskController.updateTask(
            updatedTask.taskId,
            updatedTask.title,
            updatedTask.description,
            updatedTask.status,
          );
          result.successfulOperations.add(taskId);
          Get.log('Successfully assigned task $taskId to $userId as $role');
        } catch (e) {
          result.failedOperations[taskId] = e.toString();
          Get.log('Failed to assign task $taskId: $e');
        }
      }
      
      Get.log('Bulk assignment completed: ${result.successfulOperations.length} successful, ${result.failedOperations.length} failed');
      return result;
    } catch (e) {
      Get.log('Bulk assignment operation failed: $e');
      rethrow;
    }
  }

  /// Bulk delete tasks (permanent deletion)
  Future<BulkOperationResult> bulkDeleteTasks({
    required List<String> taskIds,
    Function(int current, int total)? onProgress,
  }) async {
    if (!_isInitialized) {
      throw Exception('BulkOperationsService not initialized');
    }

    final result = BulkOperationResult();
    
    try {
      Get.log('Starting bulk deletion for ${taskIds.length} tasks');
      
      for (int i = 0; i < taskIds.length; i++) {
        final taskId = taskIds[i];
        onProgress?.call(i + 1, taskIds.length);
        
        try {
          await _taskController.deleteTask(taskId);
          result.successfulOperations.add(taskId);
          Get.log('Successfully deleted task: $taskId');
        } catch (e) {
          result.failedOperations[taskId] = e.toString();
          Get.log('Failed to delete task $taskId: $e');
        }
      }
      
      Get.log('Bulk deletion completed: ${result.successfulOperations.length} successful, ${result.failedOperations.length} failed');
      return result;
    } catch (e) {
      Get.log('Bulk deletion operation failed: $e');
      rethrow;
    }
  }

  /// Get tasks by IDs
  Future<List<Task>> getTasksByIds(List<String> taskIds) async {
    final tasks = <Task>[];
    
    for (final taskId in taskIds) {
      try {
        final task = await _taskController.getTaskById(taskId);
        if (task != null) {
          tasks.add(task);
        }
      } catch (e) {
        Get.log('Failed to get task $taskId: $e');
      }
    }
    
    return tasks;
  }

  /// Validate task IDs before bulk operation
  Future<List<String>> validateTaskIds(List<String> taskIds) async {
    final validIds = <String>[];
    
    for (final taskId in taskIds) {
      try {
        final task = await _taskController.getTaskById(taskId);
        if (task != null) {
          validIds.add(taskId);
        }
      } catch (e) {
        Get.log('Invalid task ID: $taskId');
      }
    }
    
    return validIds;
  }
}

/// Result of bulk operations
class BulkOperationResult {
  final List<String> successfulOperations = [];
  final Map<String, String> failedOperations = {};
  
  int get totalOperations => successfulOperations.length + failedOperations.length;
  int get successCount => successfulOperations.length;
  int get failureCount => failedOperations.length;
  bool get hasFailures => failedOperations.isNotEmpty;
  bool get allSuccessful => failedOperations.isEmpty && successfulOperations.isNotEmpty;
  double get successRate => totalOperations > 0 ? successCount / totalOperations : 0.0;
  
  @override
  String toString() {
    return 'BulkOperationResult(successful: $successCount, failed: $failureCount, total: $totalOperations)';
  }
}

/// Result of bulk export operations
class BulkExportResult {
  final bool success;
  final String? filePath;
  final String? error;
  final int exportedCount;
  
  BulkExportResult({
    required this.success,
    this.filePath,
    this.error,
    required this.exportedCount,
  });
  
  @override
  String toString() {
    if (success) {
      return 'BulkExportResult(success: true, exported: $exportedCount, file: $filePath)';
    } else {
      return 'BulkExportResult(success: false, error: $error)';
    }
  }
}