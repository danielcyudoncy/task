// service/export_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:task/models/task.dart';
import 'package:task/service/pdf_export_service.dart';

enum ExportFormat {
  csv,
  json,
}

class ExportProgress {
  final int current;
  final int total;
  final String status;
  final bool isComplete;
  final String? filePath;
  final String? error;

  const ExportProgress({
    required this.current,
    required this.total,
    required this.status,
    this.isComplete = false,
    this.filePath,
    this.error,
  });

  double get progress => total > 0 ? current / total : 0.0;
}

class ExportService extends GetxService {
  static ExportService get to => Get.find();

  bool _isInitialized = false;
  final _exportController = StreamController<ExportProgress>.broadcast();

  /// Stream to listen to export progress
  Stream<ExportProgress> get exportStream => _exportController.stream;

  @override
  void onClose() {
    _exportController.close();
    super.onClose();
  }

  /// Initializes the ExportService
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Create exports directory if it doesn't exist
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      // Clean up old exports
      await _cleanupOldExports();

      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize ExportService: $e');
      rethrow;
    }
  }

  /// Cleans up export files older than 7 days
  Future<void> _cleanupOldExports() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/exports');

      if (!await exportDir.exists()) return;

      final now = DateTime.now();
      final files = exportDir.listSync();

      for (var file in files) {
        if (file is File) {
          try {
            final stat = await file.stat();
            final age = now.difference(stat.modified);
            if (age.inDays > 7) {
              await file.delete();
            }
          } catch (e) {
            debugPrint('Error cleaning up file ${file.path}: $e');
            // Continue with next file
          }
        }
      }
    } catch (e) {
      debugPrint('Error in _cleanupOldExports: $e');
      // Don't rethrow - this shouldn't block the export
    }
  }

  /// Exports tasks to a file and shares it
  Future<String> exportTasks({
    required List<Map<String, dynamic>> tasks,
    ExportFormat format = ExportFormat.csv,
    String? fileName,
    bool shareAfterExport = true,
    void Function(ExportProgress)? onProgress,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Input validation
    if (tasks.isEmpty) {
      throw ArgumentError('No tasks to export');
    }

    final totalTasks = tasks.length;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final progress = ExportProgress(
      current: 0,
      total: totalTasks,
      status: 'Preparing export...',
    );

    _exportController.add(progress);
    onProgress?.call(progress);

    try {
      // Create exports directory if it doesn't exist
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/exports');
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      // Generate file content based on format
      String fileContent;
      String fileExtension;

      switch (format) {
        case ExportFormat.csv:
          fileContent = _convertToCsv(tasks, (current, status) {
            final progress = ExportProgress(
              current: current,
              total: totalTasks,
              status: status,
            );
            _exportController.add(progress);
            onProgress?.call(progress);
          });
          fileExtension = 'csv';
          break;

        case ExportFormat.json:
          fileContent = _convertToJson(tasks, (current, status) {
            final progress = ExportProgress(
              current: current,
              total: totalTasks,
              status: status,
            );
            _exportController.add(progress);
            onProgress?.call(progress);
          });
          fileExtension = 'json';
          break;
      }

      // Save to file
      final exportFileName =
          fileName ?? 'tasks_export_$timestamp.$fileExtension';
      final exportFile = File('${exportDir.path}/$exportFileName');

      await exportFile.writeAsString(fileContent);

      // Share the file if requested
      if (shareAfterExport) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(exportFile.path)],
            subject: 'Tasks Export',
            text: 'Here is the exported tasks file.',
          ),
        );
      }

      // Send completion progress
      final completeProgress = ExportProgress(
        current: totalTasks,
        total: totalTasks,
        status: 'Export completed',
        isComplete: true,
        filePath: exportFile.path,
      );
      _exportController.add(completeProgress);
      onProgress?.call(completeProgress);

      return exportFile.path;
    } catch (e, stackTrace) {
      debugPrint('Export failed: $e\n$stackTrace');

      final errorProgress = ExportProgress(
        current: 0,
        total: totalTasks,
        status: 'Export failed',
        error: 'Failed to export tasks: ${e.toString()}',
      );
      _exportController.add(errorProgress);
      onProgress?.call(errorProgress);

      rethrow;
    }
  }

  String _convertToCsv(
    List<Map<String, dynamic>> tasks,
    void Function(int current, String status) onProgress,
  ) {
    if (tasks.isEmpty) return '';

    final buffer = StringBuffer();
    final headers = tasks.first.keys.toList();

    // Add headers
    buffer.writeln(headers.map((h) => _escapeCsvField(h)).join(','));

    // Add rows
    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      final row = headers
          .map((h) => _escapeCsvField(task[h]?.toString() ?? ''))
          .toList();
      buffer.writeln(row.join(','));

      // Update progress every 10% or at least every 10 items
      if (i % 10 == 0 || i == tasks.length - 1) {
        final progress = (i + 1) * 100 ~/ tasks.length;
        onProgress(i + 1, 'Exporting... $progress%');
      }
    }

    return buffer.toString();
  }

  String _convertToJson(
    List<Map<String, dynamic>> tasks,
    void Function(int current, String status) onProgress,
  ) {
    final List<Map<String, dynamic>> jsonList = [];

    for (int i = 0; i < tasks.length; i++) {
      jsonList.add(Map<String, dynamic>.from(tasks[i]));

      // Update progress every 10% or at least every 10 items
      if (i % 10 == 0 || i == tasks.length - 1) {
        final progress = (i + 1) * 100 ~/ tasks.length;
        onProgress(i + 1, 'Exporting... $progress%');
      }
    }

    return const JsonEncoder.withIndent('  ').convert(jsonList);
  }

  String _escapeCsvField(dynamic field) {
    if (field == null) return '';
    final str = field.toString();
    if (str.contains(',') ||
        str.contains('"') ||
        str.contains('\n') ||
        str.contains('\r')) {
      return '"${str.replaceAll('"', '""')}"';
    }
    return str;
  }

  // Legacy methods for backward compatibility

  /// Export tasks to CSV format (legacy method)
  Future<File> exportToCsv(List<Task> tasks, {String? fileName}) async {
    try {
      final StringBuffer csvContent = StringBuffer();

      // Add CSV header
      csvContent.writeln(
          'Title,Description,Status,Category,Assigned Reporter,Assigned Cameraman,Assigned Driver,Assigned Librarian,Created At,Due Date,Archived At,Tags');

      // Add task data
      for (final task in tasks) {
        final tags = task.tags.join('; ');
        final row = [
          _escapeCsvField(task.title),
          _escapeCsvField(task.description),
          _escapeCsvField(task.status),
          _escapeCsvField(task.category ?? ''),
          _escapeCsvField(task.assignedReporter ?? ''),
          _escapeCsvField(task.assignedCameraman ?? ''),
          _escapeCsvField(task.assignedDriver ?? ''),
          _escapeCsvField(task.assignedLibrarian ?? ''),
          task.timestamp.toIso8601String(),
          task.dueDate?.toIso8601String() ?? '',
          task.archivedAt?.toIso8601String() ?? '',
          _escapeCsvField(tags),
        ];
        csvContent.writeln(row.join(','));
      }

      // Create file
      final directory = await getTemporaryDirectory();
      final file = File(
          '${directory.path}/${fileName ?? 'tasks_${DateTime.now().millisecondsSinceEpoch}.csv'}');
      await file.writeAsString(csvContent.toString());

      return file;
    } catch (e) {
      debugPrint('Error exporting to CSV: $e');
      rethrow;
    }
  }

  /// Export tasks to JSON format (legacy method)
  Future<File> exportToJson(List<Task> tasks, {String? fileName}) async {
    try {
      // Convert tasks to JSON
      final List<Map<String, dynamic>> jsonData =
          tasks.map((task) => task.toMap()).toList();
      final String jsonString =
          const JsonEncoder.withIndent('  ').convert(jsonData);

      // Create file
      final directory = await getTemporaryDirectory();
      final file = File(
          '${directory.path}/${fileName ?? 'tasks_${DateTime.now().millisecondsSinceEpoch}.json'}');
      await file.writeAsString(jsonString);

      return file;
    } catch (e) {
      debugPrint('Error exporting to JSON: $e');
      rethrow;
    }
  }

  /// Export tasks to PDF format
  Future<File> exportToPdf(List<Task> tasks, {String? fileName}) async {
    try {
      // Use the dedicated PDF export service for proper PDF generation
      final pdfExportService = Get.find<PdfExportService>();
      final pdfPath =
          await pdfExportService.exportTasksToPdf(tasks, title: 'Tasks Export');

      // If a custom filename is provided, rename the file
      if (fileName != null) {
        final directory = await getTemporaryDirectory();
        final newFile = File('${directory.path}/$fileName');
        final originalFile = File(pdfPath);
        await originalFile.copy(newFile.path);
        await originalFile.delete();
        return newFile;
      }

      return File(pdfPath);
    } catch (e) {
      debugPrint('Error exporting to PDF: $e');
      // Fallback to CSV if PDF export fails
      return exportToCsv(tasks, fileName: fileName?.replaceAll('.pdf', '.csv'));
    }
  }

  /// Share file using share_plus package (legacy method)
  Future<void> shareFile(File file, {String? subject, String? text}) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: subject,
          text: text,
        ),
      );
    } catch (e) {
      debugPrint('Error sharing file: $e');
      rethrow;
    }
  }

  /// Share text directly (legacy method)
  Future<void> shareText(String text, {String? subject}) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: subject,
        ),
      );
    } catch (e) {
      debugPrint('Error sharing text: $e');
      rethrow;
    }
  }

  /// Format date for display (legacy method)
  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Export tasks to CSV format
  Future<String> exportTasksToCSV(
    List<Task> tasks, {
    Function(double)? onProgress,
  }) async {
    // Convert Task objects to Map<String, dynamic>
    final taskMaps = tasks.map((task) => task.toMap()).toList();
    return await exportTasks(
      tasks: taskMaps,
      format: ExportFormat.csv,
      onProgress: onProgress != null
          ? (progress) => onProgress(progress.progress)
          : null,
    );
  }
}
