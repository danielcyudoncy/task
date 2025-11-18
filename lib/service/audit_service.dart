// service/audit_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:task/controllers/auth_controller.dart';

/// Service for logging audit events (assignments, approvals, deletions)
/// Immutable audit records help track who did what and when.
class AuditService {
  static final AuditService _instance = AuditService._internal();

  factory AuditService() {
    return _instance;
  }

  AuditService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Log an audit event to the audit_logs collection
  ///
  /// Parameters:
  /// - action: Type of action (e.g., 'task_assigned', 'task_approved', 'task_deleted', 'user_promoted')
  /// - resourceType: Type of resource (e.g., 'task', 'user')
  /// - resourceId: ID of the affected resource
  /// - changes: Map of fields that were changed (for detailed audit trail)
  /// - relatedUserId: Optional ID of another user involved (e.g., person task was assigned to)
  /// - reason: Optional reason for the action
  Future<void> logAuditEvent({
    required String action,
    required String resourceType,
    required String resourceId,
    Map<String, dynamic>? changes,
    String? relatedUserId,
    String? reason,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      final authController = AuthController.to;

      if (currentUser == null) {
        debugPrint('AuditService: Cannot log event - user not authenticated');
        return;
      }

      final auditRecord = {
        'action': action,
        'resourceType': resourceType,
        'resourceId': resourceId,
        'performedBy': currentUser.uid,
        'performedByEmail': currentUser.email,
        'performedByRole': authController.userRole.value,
        'timestamp': FieldValue.serverTimestamp(),
        'changes': changes,
        if (relatedUserId != null) 'relatedUserId': relatedUserId,
        if (reason != null) 'reason': reason,
        'ipAddress': '', // Could be populated server-side if needed
      };

      await _firestore.collection('audit_logs').add(auditRecord);

      debugPrint(
        'AuditService: Logged audit event - action=$action, resourceType=$resourceType, resourceId=$resourceId',
      );
    } catch (e) {
      // Don't fail the main operation if audit logging fails
      debugPrint('AuditService: Error logging audit event: $e');
    }
  }

  /// Log a task assignment
  Future<void> logTaskAssignment({
    required String taskId,
    required String assignedToUserId,
    required String assignedName,
    required String taskTitle,
  }) async {
    await logAuditEvent(
      action: 'task_assigned',
      resourceType: 'task',
      resourceId: taskId,
      relatedUserId: assignedToUserId,
      changes: {
        'assignedTo': assignedToUserId,
        'assignedName': assignedName,
      },
      reason: 'Task "$taskTitle" assigned to $assignedName',
    );
  }

  /// Log a task approval
  Future<void> logTaskApproval({
    required String taskId,
    required String taskTitle,
    String? reason,
  }) async {
    await logAuditEvent(
      action: 'task_approved',
      resourceType: 'task',
      resourceId: taskId,
      changes: {
        'approvalStatus': 'approved',
      },
      reason: reason ?? 'Task "$taskTitle" approved',
    );
  }

  /// Log a task rejection
  Future<void> logTaskRejection({
    required String taskId,
    required String taskTitle,
    String? reason,
  }) async {
    await logAuditEvent(
      action: 'task_rejected',
      resourceType: 'task',
      resourceId: taskId,
      changes: {
        'approvalStatus': 'rejected',
      },
      reason: reason ?? 'Task "$taskTitle" rejected',
    );
  }

  /// Log a task deletion
  Future<void> logTaskDeletion({
    required String taskId,
    required String taskTitle,
    String? reason,
  }) async {
    await logAuditEvent(
      action: 'task_deleted',
      resourceType: 'task',
      resourceId: taskId,
      reason: reason ?? 'Task "$taskTitle" deleted',
    );
  }

  /// Log a user promotion to admin
  Future<void> logUserPromotion({
    required String userId,
    required String userEmail,
    required String userName,
  }) async {
    await logAuditEvent(
      action: 'user_promoted_to_admin',
      resourceType: 'user',
      resourceId: userId,
      relatedUserId: userId,
      changes: {
        'role': 'admin',
      },
      reason: 'User "$userName" ($userEmail) promoted to admin',
    );
  }

  /// Log a user deletion
  Future<void> logUserDeletion({
    required String userId,
    required String userEmail,
    required String userName,
  }) async {
    await logAuditEvent(
      action: 'user_deleted',
      resourceType: 'user',
      resourceId: userId,
      reason: 'User "$userName" ($userEmail) deleted',
    );
  }

  /// Retrieve recent audit logs (last N entries)
  Future<List<Map<String, dynamic>>> getRecentAuditLogs({
    int limit = 50,
    String? filterByAction,
    String? filterByResourceType,
  }) async {
    try {
      Query query = _firestore
          .collection('audit_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (filterByAction != null) {
        query = query.where('action', isEqualTo: filterByAction);
      }

      if (filterByResourceType != null) {
        query = query.where('resourceType', isEqualTo: filterByResourceType);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => {
                ...doc.data() as Map<String, dynamic>,
                'id': doc.id,
              })
          .toList();
    } catch (e) {
      debugPrint('AuditService: Error retrieving audit logs: $e');
      return [];
    }
  }

  /// Retrieve audit logs for a specific resource
  Future<List<Map<String, dynamic>>> getAuditLogsForResource({
    required String resourceId,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('audit_logs')
          .where('resourceId', isEqualTo: resourceId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'id': doc.id,
              })
          .toList();
    } catch (e) {
      debugPrint('AuditService: Error retrieving audit logs for resource: $e');
      return [];
    }
  }
}
