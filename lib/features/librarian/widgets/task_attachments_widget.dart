// features/librarian/widgets/task_attachments_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:task/models/task_model.dart';
import 'package:task/service/task_attachment_service.dart';
import 'package:url_launcher/url_launcher.dart';

class TaskAttachmentsWidget extends StatefulWidget {
  final Task task;
  final Function(Task)? onTaskUpdated;
  final bool isReadOnly;

  const TaskAttachmentsWidget({
    super.key,
    required this.task,
    this.onTaskUpdated,
    this.isReadOnly = false,
  });

  @override
  State<TaskAttachmentsWidget> createState() => _TaskAttachmentsWidgetState();
}

class _TaskAttachmentsWidgetState extends State<TaskAttachmentsWidget> {
  final TaskAttachmentService _attachmentService = Get.find<TaskAttachmentService>();
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.attach_file,
                  color: colorScheme.onSurface,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Attachments',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (!widget.isReadOnly) ...[
                  // Add attachment button
                  PopupMenuButton<String>(
                    onSelected: _handleAddAttachment,
                    enabled: !_isUploading,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'camera',
                        child: Row(
                          children: [
                            Icon(Icons.camera_alt),
                            SizedBox(width: 8),
                            Text('Take Photo'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'gallery',
                        child: Row(
                          children: [
                            Icon(Icons.photo_library),
                            SizedBox(width: 8),
                            Text('Choose Image'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'document',
                        child: Row(
                          children: [
                            Icon(Icons.description),
                            SizedBox(width: 8),
                            Text('Upload Document'),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            color: colorScheme.onPrimary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Add',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            
            // Loading indicator
            if (_isUploading)
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Uploading attachment...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Attachments list
            if (widget.task.attachmentUrls.isEmpty && !_isUploading)
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.attach_file_outlined,
                      size: 48,
                      color: theme.hintColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No attachments yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    if (!widget.isReadOnly) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tap the + button to add files',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.task.attachmentUrls.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _buildAttachmentItem(context, index);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(BuildContext context, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final url = widget.task.attachmentUrls[index];
    final name = widget.task.attachmentNames[index];
    final type = widget.task.attachmentTypes[index];
    final size = widget.task.attachmentSizes[index];
    
    final icon = _attachmentService.getFileTypeIcon(type);
    final formattedSize = _attachmentService.formatFileSize(size);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // File type icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getTypeColor(type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: _getTypeColor(type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          
          // File details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      type.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getTypeColor(type),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      ' • $formattedSize',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // View/Download button
              IconButton(
                onPressed: () => _openAttachment(url),
                icon: Icon(
                  type == 'image' ? Icons.visibility : Icons.download,
                  color: colorScheme.primary,
                  size: 20,
                ),
                tooltip: type == 'image' ? 'View' : 'Download',
              ),
              
              // Delete button (only if not read-only)
              if (!widget.isReadOnly)
                IconButton(
                  onPressed: () => _removeAttachment(index),
                  icon: Icon(
                    Icons.delete_outline,
                    color: colorScheme.error,
                    size: 20,
                  ),
                  tooltip: 'Remove',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    final colorScheme = Theme.of(context).colorScheme;
    
    switch (type.toLowerCase()) {
      case 'image':
        return colorScheme.secondary;
      case 'video':
        return colorScheme.tertiary;
      case 'audio':
        return colorScheme.primary;
      case 'document':
        return colorScheme.outline;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  Future<void> _handleAddAttachment(String type) async {
    if (_isUploading) return;
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      Map<String, dynamic>? result;
      
      switch (type) {
        case 'camera':
          result = await _attachmentService.pickAndUploadImage(
            taskId: widget.task.taskId,
            source: ImageSource.camera,
          );
          break;
        case 'gallery':
          result = await _attachmentService.pickAndUploadImage(
            taskId: widget.task.taskId,
            source: ImageSource.gallery,
          );
          break;
        case 'document':
          result = await _attachmentService.pickAndUploadDocument(
            taskId: widget.task.taskId,
          );
          break;
      }
      
      if (result != null) {
        // Add attachment to task
        await _attachmentService.addAttachmentToTask(
          taskId: widget.task.taskId,
          url: result['url'],
          name: result['name'],
          type: result['type'],
          size: result['size'],
        );
        
        // Update local task object
        final updatedTask = widget.task.copyWith(
          attachmentUrls: [...widget.task.attachmentUrls, result['url']],
          attachmentNames: [...widget.task.attachmentNames, result['name']],
          attachmentTypes: [...widget.task.attachmentTypes, result['type']],
          attachmentSizes: [...widget.task.attachmentSizes, result['size']],
          lastAttachmentAdded: result['uploadedAt'],
        );
        
        widget.onTaskUpdated?.call(updatedTask);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attachment "${result['name']}" uploaded successfully'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload attachment: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _removeAttachment(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Attachment'),
        content: Text(
          'Are you sure you want to remove "${widget.task.attachmentNames[index]}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      await _attachmentService.removeAttachmentFromTask(
        taskId: widget.task.taskId,
        attachmentIndex: index,
        task: widget.task,
      );
      
      // Update local task object
      final updatedUrls = List<String>.from(widget.task.attachmentUrls);
      final updatedNames = List<String>.from(widget.task.attachmentNames);
      final updatedTypes = List<String>.from(widget.task.attachmentTypes);
      final updatedSizes = List<int>.from(widget.task.attachmentSizes);
      
      updatedUrls.removeAt(index);
      updatedNames.removeAt(index);
      updatedTypes.removeAt(index);
      updatedSizes.removeAt(index);
      
      final updatedTask = widget.task.copyWith(
        attachmentUrls: updatedUrls,
        attachmentNames: updatedNames,
        attachmentTypes: updatedTypes,
        attachmentSizes: updatedSizes,
      );
      
      widget.onTaskUpdated?.call(updatedTask);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Attachment removed successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove attachment: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _openAttachment(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open attachment: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}