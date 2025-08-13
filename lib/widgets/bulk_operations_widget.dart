// widgets/bulk_operations_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/models/task_model.dart';
import 'package:task/service/bulk_operations_service.dart';
import 'package:task/utils/constants/app_colors.dart';
import 'package:task/utils/constants/app_sizes.dart';
import 'package:task/utils/constants/app_styles.dart';

class BulkOperationsWidget extends StatefulWidget {
  final List<Task> selectedTasks;
  final VoidCallback onOperationComplete;
  final bool isVisible;

  const BulkOperationsWidget({
    super.key,
    required this.selectedTasks,
    required this.onOperationComplete,
    required this.isVisible,
  });

  @override
  State<BulkOperationsWidget> createState() => _BulkOperationsWidgetState();
}

class _BulkOperationsWidgetState extends State<BulkOperationsWidget>
    with SingleTickerProviderStateMixin {
  final BulkOperationsService _bulkService = BulkOperationsService.to;
  final TextEditingController _archiveReasonController = TextEditingController();
  final TextEditingController _archiveLocationController = TextEditingController();
  final TextEditingController _exportFileNameController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  bool _isLoading = false;
  String? _selectedStatus;
  double _operationProgress = 0.0;
  String _operationStatus = '';

  final List<String> _statusOptions = [
    'Pending',
    'In Progress',
    'Completed',
    'On Hold',
    'Cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(BulkOperationsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _archiveReasonController.dispose();
    _archiveLocationController.dispose();
    _exportFileNameController.dispose();
    super.dispose();
  }

  void _updateProgress(int current, int total) {
    setState(() {
      _operationProgress = current / total;
      _operationStatus = 'Processing $current of $total tasks...';
    });
  }

  Future<void> _showArchiveDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Archive ${widget.selectedTasks.length} Tasks',
            style: AppStyles.sectionTitleStyle,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _archiveReasonController,
                decoration: const InputDecoration(
                  labelText: 'Archive Reason *',
                  hintText: 'Enter reason for archiving',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _archiveLocationController,
                decoration: const InputDecoration(
                  labelText: 'Archive Location (Optional)',
                  hintText: 'Enter archive location',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _archiveReasonController.text.isNotEmpty
                  ? () {
                      Navigator.of(context).pop();
                      _performBulkArchive();
                    }
                  : null,
              child: const Text('Archive'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performBulkArchive() async {
    if (_archiveReasonController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Archive reason is required',
        backgroundColor: AppColors.errorRed,
         colorText: AppColors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _operationProgress = 0.0;
      _operationStatus = 'Starting archive operation...';
    });

    try {
      final taskIds = widget.selectedTasks.map((task) => task.taskId).toList();
      final result = await _bulkService.bulkArchiveTasks(
        taskIds: taskIds,
        reason: _archiveReasonController.text,
        location: _archiveLocationController.text.isNotEmpty 
            ? _archiveLocationController.text 
            : null,
        onProgress: _updateProgress,
      );

      _showResultDialog('Archive Operation Complete', result);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Archive operation failed: $e',
        backgroundColor: AppColors.errorRed,
        colorText: AppColors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
        _operationProgress = 0.0;
        _operationStatus = '';
      });
      _archiveReasonController.clear();
      _archiveLocationController.clear();
      widget.onOperationComplete();
    }
  }

  Future<void> _performBulkUnarchive() async {
    setState(() {
      _isLoading = true;
      _operationProgress = 0.0;
      _operationStatus = 'Starting unarchive operation...';
    });

    try {
      final taskIds = widget.selectedTasks.map((task) => task.taskId).toList();
      final result = await _bulkService.bulkUnarchiveTasks(
        taskIds: taskIds,
        onProgress: _updateProgress,
      );

      _showResultDialog('Unarchive Operation Complete', result);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Unarchive operation failed: $e',
        backgroundColor: AppColors.errorRed,
        colorText: AppColors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
        _operationProgress = 0.0;
        _operationStatus = '';
      });
      widget.onOperationComplete();
    }
  }

  Future<void> _performBulkExport(String format) async {
    setState(() {
      _isLoading = true;
      _operationProgress = 0.0;
      _operationStatus = 'Starting export operation...';
    });

    try {
      BulkExportResult result;
      
      if (format == 'CSV') {
        result = await _bulkService.bulkExportTasksToCSV(
          tasks: widget.selectedTasks,
          fileName: _exportFileNameController.text.isNotEmpty 
              ? _exportFileNameController.text 
              : null,
          onProgress: _updateProgress,
        );
      } else {
        result = await _bulkService.bulkExportTasksToPDF(
          tasks: widget.selectedTasks,
          title: _exportFileNameController.text.isNotEmpty 
              ? _exportFileNameController.text 
              : 'Bulk Task Export',
          onProgress: _updateProgress,
        );
      }

      if (result.success) {
        Get.snackbar(
        'Export Complete',
        'Successfully exported ${result.exportedCount} tasks to $format',
        backgroundColor: AppColors.saveColor,
        colorText: AppColors.white,
      );
      } else {
        Get.snackbar(
          'Export Failed',
          result.error ?? 'Unknown error occurred',
          backgroundColor: AppColors.errorRed,
          colorText: AppColors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Export operation failed: $e',
        backgroundColor: AppColors.errorRed,
          colorText: AppColors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
        _operationProgress = 0.0;
        _operationStatus = '';
      });
      _exportFileNameController.clear();
      widget.onOperationComplete();
    }
  }

  Future<void> _performBulkStatusUpdate() async {
    if (_selectedStatus == null) {
      Get.snackbar(
        'Error',
        'Please select a status',
        backgroundColor: AppColors.errorRed,
        colorText: AppColors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _operationProgress = 0.0;
      _operationStatus = 'Updating task statuses...';
    });

    try {
      final taskIds = widget.selectedTasks.map((task) => task.taskId).toList();
      final result = await _bulkService.bulkUpdateTaskStatus(
        taskIds: taskIds,
        newStatus: _selectedStatus!,
        onProgress: _updateProgress,
      );

      _showResultDialog('Status Update Complete', result);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Status update failed: $e',
        backgroundColor: AppColors.errorRed,
          colorText: AppColors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
        _operationProgress = 0.0;
        _operationStatus = '';
        _selectedStatus = null;
      });
      widget.onOperationComplete();
    }
  }

  Future<void> _performBulkDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to permanently delete ${widget.selectedTasks.length} tasks? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _operationProgress = 0.0;
      _operationStatus = 'Deleting tasks...';
    });

    try {
      final taskIds = widget.selectedTasks.map((task) => task.taskId).toList();
      final result = await _bulkService.bulkDeleteTasks(
        taskIds: taskIds,
        onProgress: _updateProgress,
      );

      _showResultDialog('Deletion Complete', result);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Deletion failed: $e',
        backgroundColor: AppColors.errorRed,
        colorText: AppColors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
        _operationProgress = 0.0;
        _operationStatus = '';
      });
      widget.onOperationComplete();
    }
  }

  void _showResultDialog(String title, BulkOperationResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total operations: ${result.totalOperations}'),
            Text(
              'Successful: ${result.successCount}',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
            if (result.hasFailures) ...[
              Text(
                'Failed: ${result.failureCount}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 8),
              Text(
                'Success rate: ${(result.successRate * 100).toStringAsFixed(1)}%',
                style: AppStyles.sectionTitleStyle,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _slideAnimation.value) * 100),
          child: Opacity(
            opacity: _slideAnimation.value,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.lightGrey,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.checklist,
                        color: AppColors.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bulk Operations (${widget.selectedTasks.length} tasks)',
                        style: AppStyles.sectionTitleStyle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_isLoading) ...[
                    LinearProgressIndicator(
                      value: _operationProgress,
                      backgroundColor: AppColors.lightGrey,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _operationStatus,
                      style: TextStyle(
                         fontSize: AppSizes.fontSm,
                         color: AppColors.secondaryText,
                       ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Archive Operations
                  _buildOperationSection(
                    'Archive Operations',
                    [
                      _buildOperationButton(
                        'Archive Tasks',
                        Icons.archive,
                        _showArchiveDialog,
                        AppColors.secondaryColor,
                      ),
                      _buildOperationButton(
                        'Unarchive Tasks',
                        Icons.unarchive,
                        _performBulkUnarchive,
                        AppColors.tertiaryColor,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Export Operations
                  _buildOperationSection(
                    'Export Operations',
                    [
                      _buildOperationButton(
                        'Export to CSV',
                        Icons.table_chart,
                        () => _performBulkExport('CSV'),
                        AppColors.saveColor,
                      ),
                      _buildOperationButton(
                        'Export to PDF',
                        Icons.picture_as_pdf,
                        () => _performBulkExport('PDF'),
                        AppColors.primaryColor,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Status Update
                  _buildOperationSection(
                    'Status Update',
                    [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'New Status',
                                border: OutlineInputBorder(),
                              ),
                              items: _statusOptions.map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildOperationButton(
                            'Update',
                            Icons.update,
                            _performBulkStatusUpdate,
                            AppColors.tertiaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Danger Zone
                  _buildOperationSection(
                    'Danger Zone',
                    [
                      _buildOperationButton(
                        'Delete Tasks',
                        Icons.delete_forever,
                        _performBulkDelete,
                        AppColors.errorRed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOperationSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AppSizes.fontLg,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children,
        ),
      ],
    );
  }

  Widget _buildOperationButton(
    String text,
    IconData icon,
    VoidCallback onPressed,
    Color color,
  ) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(icon, size: 18),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}