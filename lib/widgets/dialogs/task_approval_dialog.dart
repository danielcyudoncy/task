// widgets/dialogs/task_approval_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin_controller.dart';

class TaskApprovalDialog {
  static void show({
    required BuildContext context,
    required String taskId,
    required String title,
    required String description,
    required String createdBy,
    required String creatorName,
    required String creatorRole,
    required String status,
    required String priority,
    required String category,
    required String dueDate,
    required List<String> tags,
    required List<String> attachmentUrls,
    required List<String> attachmentNames,
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2C3E50)
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(context, title, status),
                _buildContent(
                  context,
                  taskId,
                  description,
                  createdBy,
                  creatorName,
                  creatorRole,
                  priority,
                  category,
                  dueDate,
                  tags,
                  attachmentUrls,
                  attachmentNames,
                ),
                _buildFooter(context, onApprove, onReject),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildHeader(BuildContext context, String title, String status) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4A90E2),
            const Color(0xFF357ABD),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.approval,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task Approval',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withAlpha(2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withAlpha(2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildContent(
    BuildContext context,
    String taskId,
    String description,
    String createdBy,
    String creatorName,
    String creatorRole,
    String priority,
    String category,
    String dueDate,
    List<String> tags,
    List<String> attachmentUrls,
    List<String> attachmentNames,
  ) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              'Description',
              Icons.description,
              Text(
                description.isNotEmpty ? description : 'No description provided',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Task Details',
              Icons.info_outline,
              Column(
                children: [
                  _buildDetailRow(context, 'Task ID', taskId),
                  _buildDetailRow(context, 'Priority', priority),
                  _buildDetailRow(context, 'Category', category),
                  _buildDetailRow(context, 'Due Date', dueDate),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              'Creator Information',
              Icons.person,
              Column(
                children: [
                  _buildDetailRow(context, 'Name', creatorName),
                  _buildDetailRow(context, 'Role', creatorRole),
                  _buildDetailRow(context, 'User ID', createdBy),
                ],
              ),
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSection(
                context,
                'Tags',
                Icons.label,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((tag) => _buildTag(context, tag)).toList(),
                ),
              ),
            ],
            if (attachmentUrls.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSection(
                context,
                'Attachments',
                Icons.attach_file,
                Column(
                  children: List.generate(
                    attachmentUrls.length,
                    (index) => _buildAttachmentItem(
                      context,
                      attachmentNames.length > index
                          ? attachmentNames[index]
                          : 'Attachment ${index + 1}',
                      attachmentUrls[index],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    Widget content,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF34495E)
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withAlpha(1)
              : Colors.grey.withAlpha(2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withAlpha(1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF4A90E2),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  static Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70
                    : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildTag(BuildContext context, String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4A90E2).withAlpha(1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4A90E2).withAlpha(3),
        ),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF4A90E2),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static Widget _buildAttachmentItem(BuildContext context, String name, String url) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2C3E50)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withAlpha(1)
              : Colors.grey.withAlpha(3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.attach_file,
            size: 20,
            color: Color(0xFF4A90E2),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () {
              // Handle attachment download/view
            },
            icon: const Icon(
              Icons.download,
              size: 18,
              color: Color(0xFF4A90E2),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildFooter(
    BuildContext context,
    VoidCallback onApprove,
    VoidCallback onReject,
  ) {
    final AdminController adminController = Get.find<AdminController>();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF34495E)
            : const Color(0xFFF8F9FA),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(() => ElevatedButton(
              onPressed: adminController.isLoading.value ? null : () {
                Navigator.of(context).pop();
                onReject();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: adminController.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Reject',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            )),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Obx(() => ElevatedButton(
              onPressed: adminController.isLoading.value ? null : () {
                Navigator.of(context).pop();
                onApprove();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: adminController.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Approve',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            )),
          ),
        ],
      ),
    );
  }

  static Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF39C12);
      case 'approved':
        return const Color(0xFF27AE60);
      case 'rejected':
        return const Color(0xFFE74C3C);
      case 'in_progress':
        return const Color(0xFF3498DB);
      case 'completed':
        return const Color(0xFF9B59B6);
      default:
        return const Color(0xFF95A5A6);
    }
  }
}