// widgets/approval_status_chip.dart
import 'package:flutter/material.dart';

class ApprovalStatusChip extends StatelessWidget {
  final String? approvalStatus;

  const ApprovalStatusChip({
    super.key,
    required this.approvalStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (approvalStatus == null || approvalStatus == 'pending') {
      return const SizedBox.shrink();
    }

    final bool isApproved = approvalStatus == 'approved';
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isApproved ? Colors.green : Colors.red,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isApproved ? Icons.check : Icons.close,
        size: 12,
        color: Colors.white,
      ),
    );
  }
}