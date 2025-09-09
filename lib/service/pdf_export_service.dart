// service/pdf_export_service.dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:task/models/task_model.dart';


class PdfExportService extends GetxService {
  static PdfExportService get to => Get.find();
  
  bool _isInitialized = false;
  late pw.Font _regularFont;
  late pw.Font _boldFont;
  
  /// Initializes the PDF export service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      Get.log('PdfExportService: Initializing...');
      
      // Load fonts
      await _loadFonts();
      
      _isInitialized = true;
      Get.log('PdfExportService: Initialized successfully');
    } catch (e) {
      Get.log('PdfExportService: Initialization failed: $e');
      _isInitialized = false;
      rethrow;
    }
  }
  
  /// Loads fonts for PDF generation
  Future<void> _loadFonts() async {
    try {
      // Try to load custom fonts, fallback to default if not available
      try {
        final regularFontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
        final boldFontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
        
        _regularFont = pw.Font.ttf(regularFontData);
        _boldFont = pw.Font.ttf(boldFontData);
      } catch (e) {
        // Fallback to built-in fonts
        _regularFont = pw.Font.helvetica();
        _boldFont = pw.Font.helveticaBold();
      }
    } catch (e) {
      Get.log('Error loading fonts: $e');
      // Use built-in fonts as last resort
      _regularFont = pw.Font.helvetica();
      _boldFont = pw.Font.helveticaBold();
    }
  }

  /// Exports a single task to PDF
  Future<String> exportTaskToPdf(Task task) async {
    if (!_isInitialized) {
      throw Exception('PdfExportService not initialized');
    }

    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('MMM d, y HH:mm');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 20),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(width: 2, color: PdfColors.blue),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Task Report',
                      style: pw.TextStyle(
                        font: _boldFont,
                        fontSize: 24,
                        color: PdfColors.blue,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Generated on ${dateFormat.format(DateTime.now())}',
                      style: pw.TextStyle(
                        font: _regularFont,
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Task Details
              _buildTaskDetailsSection(task, dateFormat),
              
              pw.SizedBox(height: 20),
              
              // Assignment Details
              if (_hasAssignments(task))
                _buildAssignmentSection(task),
              
              pw.SizedBox(height: 20),
              
              // Timeline
              _buildTimelineSection(task, dateFormat),
              
              pw.SizedBox(height: 20),
              
              // Attachments
              if (task.attachmentUrls.isNotEmpty)
                _buildAttachmentsSection(task),
              
              pw.SizedBox(height: 20),
              
              // Comments
              if (task.comments.isNotEmpty)
                _buildCommentsSection(task),
              
              pw.SizedBox(height: 20),
              
              // Archive Information
              if (task.isArchived)
                _buildArchiveSection(task, dateFormat),
            ];
          },
        ),
      );

      return await _savePdfToFile(pdf, 'task_${task.taskId}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    } catch (e) {
      Get.log('Error exporting task to PDF: $e');
      rethrow;
    }
  }

  /// Exports multiple tasks to PDF
  Future<String> exportTasksToPdf(List<Task> tasks, {String? title}) async {
    if (!_isInitialized) {
      throw Exception('PdfExportService not initialized');
    }

    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('MMM d, y HH:mm');
      final reportTitle = title ?? 'Tasks Report';

      // Summary page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 20),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(width: 2, color: PdfColors.blue),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        reportTitle,
                        style: pw.TextStyle(
                          font: _boldFont,
                          fontSize: 24,
                          color: PdfColors.blue,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Generated on ${dateFormat.format(DateTime.now())}',
                        style: pw.TextStyle(
                          font: _regularFont,
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 30),
                
                // Summary statistics
                _buildSummarySection(tasks),
                
                pw.SizedBox(height: 30),
                
                // Tasks overview table
                _buildTasksOverviewTable(tasks, dateFormat),
              ],
            );
          },
        ),
      );

      // Individual task pages
      for (final task in tasks) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            build: (pw.Context context) {
              return [
                // Task header
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 15),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(width: 1, color: PdfColors.grey300),
                    ),
                  ),
                  child: pw.Text(
                    'Task Details: ${task.title}',
                    style: pw.TextStyle(
                      font: _boldFont,
                      fontSize: 18,
                      color: PdfColors.blue,
                    ),
                  ),
                ),
                
                pw.SizedBox(height: 15),
                
                // Task content
                _buildTaskDetailsSection(task, dateFormat),
                
                if (_hasAssignments(task)) ...[
                  pw.SizedBox(height: 15),
                  _buildAssignmentSection(task),
                ],
                
                pw.SizedBox(height: 15),
                _buildTimelineSection(task, dateFormat),
                
                if (task.attachmentUrls.isNotEmpty) ...[
                  pw.SizedBox(height: 15),
                  _buildAttachmentsSection(task),
                ],
                
                if (task.comments.isNotEmpty) ...[
                  pw.SizedBox(height: 15),
                  _buildCommentsSection(task),
                ],
                
                if (task.isArchived) ...[
                  pw.SizedBox(height: 15),
                  _buildArchiveSection(task, dateFormat),
                ],
              ];
            },
          ),
        );
      }

      return await _savePdfToFile(pdf, 'tasks_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    } catch (e) {
      Get.log('Error exporting tasks to PDF: $e');
      rethrow;
    }
  }

  /// Builds task details section
  pw.Widget _buildTaskDetailsSection(Task task, DateFormat dateFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Task Information',
            style: pw.TextStyle(font: _boldFont, fontSize: 16),
          ),
          pw.SizedBox(height: 12),
          
          _buildDetailRow('Title', task.title),
          _buildDetailRow('Description', task.description.isNotEmpty ? task.description : 'No description'),
          _buildDetailRow('Status', task.status),
          _buildDetailRow('Category', task.category ?? 'Uncategorized'),
          _buildDetailRow('Priority', task.priority ?? 'Not specified'),
          _buildDetailRow('Tags', task.tags.isNotEmpty ? task.tags.join(', ') : 'No tags'),
          _buildDetailRow('Created By', _getCreatorName(task)),
        ],
      ),
    );
  }

  /// Builds assignment section
  pw.Widget _buildAssignmentSection(Task task) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Assignments',
            style: pw.TextStyle(font: _boldFont, fontSize: 16),
          ),
          pw.SizedBox(height: 12),
          
          if (task.assignedReporter != null)
            _buildDetailRow('Reporter', task.assignedReporter!),
          if (task.assignedCameraman != null)
            _buildDetailRow('Cameraman', task.assignedCameraman!),
          if (task.assignedDriver != null)
            _buildDetailRow('Driver', task.assignedDriver!),
          if (task.assignedLibrarian != null)
            _buildDetailRow('Librarian', task.assignedLibrarian!),
        ],
      ),
    );
  }

  /// Builds timeline section
  pw.Widget _buildTimelineSection(Task task, DateFormat dateFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Timeline',
            style: pw.TextStyle(font: _boldFont, fontSize: 16),
          ),
          pw.SizedBox(height: 12),
          
          _buildDetailRow('Created', dateFormat.format(task.timestamp.toLocal())),
          if (task.dueDate != null)
            _buildDetailRow('Due Date', dateFormat.format(task.dueDate!.toLocal())),
          if (task.lastModified != null)
            _buildDetailRow('Last Modified', dateFormat.format(task.lastModified!.toLocal())),
        ],
      ),
    );
  }

  /// Builds attachments section
  pw.Widget _buildAttachmentsSection(Task task) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Attachments (${task.attachmentUrls.length})',
            style: pw.TextStyle(font: _boldFont, fontSize: 16),
          ),
          pw.SizedBox(height: 12),
          
          ...List.generate(task.attachmentUrls.length, (index) {
            final name = task.attachmentNames[index];
            final type = task.attachmentTypes[index];
            final size = _formatFileSize(task.attachmentSizes[index]);
            
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                '• $name ($type, $size)',
                style: pw.TextStyle(font: _regularFont, fontSize: 12),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Builds comments section
  pw.Widget _buildCommentsSection(Task task) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Comments (${task.comments.length})',
            style: pw.TextStyle(font: _boldFont, fontSize: 16),
          ),
          pw.SizedBox(height: 12),
          
          ...task.comments.map((comment) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text(
              '• $comment',
              style: pw.TextStyle(font: _regularFont, fontSize: 12),
            ),
          )),
        ],
      ),
    );
  }

  /// Builds archive section
  pw.Widget _buildArchiveSection(Task task, DateFormat dateFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.orange),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Archive Information',
            style: pw.TextStyle(font: _boldFont, fontSize: 16, color: PdfColors.orange),
          ),
          pw.SizedBox(height: 12),
          
          if (task.archivedAt != null)
            _buildDetailRow('Archived At', dateFormat.format(task.archivedAt!.toLocal())),
          if (task.archivedBy != null)
            _buildDetailRow('Archived By', task.archivedBy!),
          if (task.archiveReason != null)
            _buildDetailRow('Reason', task.archiveReason!),
          if (task.archiveLocation != null)
            _buildDetailRow('Location', task.archiveLocation!),
        ],
      ),
    );
  }

  /// Builds summary section for multiple tasks
  pw.Widget _buildSummarySection(List<Task> tasks) {
    final statusCounts = <String, int>{};
    final categoryCounts = <String, int>{};
    
    for (final task in tasks) {
      statusCounts[task.status] = (statusCounts[task.status] ?? 0) + 1;
      final category = task.category ?? 'Uncategorized';
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Summary',
            style: pw.TextStyle(font: _boldFont, fontSize: 16),
          ),
          pw.SizedBox(height: 12),
          
          _buildDetailRow('Total Tasks', tasks.length.toString()),
          _buildDetailRow('Archived Tasks', tasks.where((t) => t.isArchived).length.toString()),
          
          pw.SizedBox(height: 8),
          pw.Text(
            'Status Distribution:',
            style: pw.TextStyle(font: _boldFont, fontSize: 12),
          ),
          ...statusCounts.entries.map((entry) => 
            pw.Text(
              '  • ${entry.key}: ${entry.value}',
              style: pw.TextStyle(font: _regularFont, fontSize: 10),
            ),
          ),
          
          pw.SizedBox(height: 8),
          pw.Text(
            'Category Distribution:',
            style: pw.TextStyle(font: _boldFont, fontSize: 12),
          ),
          ...categoryCounts.entries.map((entry) => 
            pw.Text(
              '  • ${entry.key}: ${entry.value}',
              style: pw.TextStyle(font: _regularFont, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds tasks overview table
  pw.Widget _buildTasksOverviewTable(List<Task> tasks, DateFormat dateFormat) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableCell('Title', isHeader: true),
            _buildTableCell('Status', isHeader: true),
            _buildTableCell('Category', isHeader: true),
            _buildTableCell('Created', isHeader: true),
          ],
        ),
        // Data rows
        ...tasks.map((task) => pw.TableRow(
          children: [
            _buildTableCell(task.title),
            _buildTableCell(task.status),
            _buildTableCell(task.category ?? 'Uncategorized'),
            _buildTableCell(dateFormat.format(task.timestamp.toLocal())),
          ],
        )),
      ],
    );
  }

  /// Builds a table cell
  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: isHeader ? _boldFont : _regularFont,
          fontSize: isHeader ? 12 : 10,
        ),
      ),
    );
  }

  /// Builds a detail row
  pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(font: _boldFont, fontSize: 12),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(font: _regularFont, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Checks if task has assignments
  bool _hasAssignments(Task task) {
    return task.assignedReporter != null ||
           task.assignedCameraman != null ||
           task.assignedDriver != null ||
           task.assignedLibrarian != null;
  }

  /// Formats file size
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Saves PDF to file and returns the file path
  Future<String> _savePdfToFile(pw.Document pdf, String fileName) async {
    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      return file.path;
    } catch (e) {
      Get.log('Error saving PDF file: $e');
      rethrow;
    }
  }

  /// Shares a PDF file
  Future<void> sharePdf(String filePath, {String? subject}) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: subject ?? 'Task Report',
        ),
      );
    } catch (e) {
      Get.log('Error sharing PDF: $e');
      rethrow;
    }
  }

  /// Exports and shares a single task
  Future<void> exportAndShareTask(Task task) async {
    try {
      final filePath = await exportTaskToPdf(task);
      await sharePdf(filePath, subject: 'Task Report: ${task.title}');
    } catch (e) {
      Get.log('Error exporting and sharing task: $e');
      rethrow;
    }
  }

  /// Exports and shares multiple tasks
  Future<void> exportAndShareTasks(List<Task> tasks, {String? title}) async {
    try {
      final filePath = await exportTasksToPdf(tasks, title: title);
      await sharePdf(filePath, subject: title ?? 'Tasks Report');
    } catch (e) {
      Get.log('Error exporting and sharing tasks: $e');
      rethrow;
    }
  }

  /// Gets the creator name for a task, preferring cached names over IDs
  String _getCreatorName(Task task) {
    try {
      // 1. Fallback to createdBy field first (synchronous)
      if (task.createdBy.isNotEmpty) {
        return task.createdBy;
      }

      // 2. Final fallback
      return 'Unknown';
    } catch (e) {
      Get.log('Error getting creator name: $e');
      return task.createdBy.isNotEmpty ? task.createdBy : 'Unknown';
    }
  }
}