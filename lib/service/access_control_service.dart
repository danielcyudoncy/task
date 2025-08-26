// service/access_control_service.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task/models/task_model.dart';
import 'package:task/controllers/user_controller.dart';

class AccessControlService extends GetxService {
  static AccessControlService get to => Get.find();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final UserController _userController;
  bool _isInitialized = false;
  
  /// Initializes the access control service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      Get.log('AccessControlService: Initializing...');
      _userController = Get.find<UserController>();
      _isInitialized = true;
      Get.log('AccessControlService: Initialized successfully');
    } catch (e) {
      Get.log('AccessControlService: Initialization failed: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Checks if user can view a specific field
  Future<bool> canViewField({
    required String userId,
    required String fieldName,
    required Task task,
  }) async {
    if (!_isInitialized) {
      throw Exception('AccessControlService not initialized');
    }

    try {
      final user = await _userController.getUserById(userId);
      if (user == null) return false;
      
      // Admin can view all fields
      if (user['role'] == 'Admin') return true;
      
      // Get field permissions
      final permissions = await _getFieldPermissions(fieldName);
      
      // Check role-based access
      if (permissions.allowedRoles.contains(user['role'])) {
        return true;
      }
      
      // Check if user is assigned to the task
      if (_isUserAssignedToTask(user, task)) {
        return permissions.allowAssignedUsers;
      }
      
      // Check if user created the task
      if (task.createdBy == user['id']) {
        return permissions.allowCreator;
      }
      
      return false;
    } catch (e) {
      Get.log('Failed to check view permission for field $fieldName: $e');
      return false;
    }
  }

  /// Checks if user can edit a specific field
  Future<bool> canEditField({
    required String userId,
    required String fieldName,
    required Task task,
  }) async {
    if (!_isInitialized) {
      throw Exception('AccessControlService not initialized');
    }

    try {
      final user = await _userController.getUserById(userId);
      if (user == null) return false;
      
      // Admin can edit all fields
      if (user['role'] == 'Admin') return true;
      
      // Get field permissions
      final permissions = await _getFieldPermissions(fieldName);
      
      // Check if field is editable
      if (!permissions.isEditable) return false;
      
      // Check role-based edit access
      if (permissions.editableByRoles.contains(user['role'])) {
        return true;
      }
      
      // Check if user is assigned to the task and has edit permission
      if (_isUserAssignedToTask(user, task)) {
        return permissions.editableByAssignedUsers;
      }
      
      // Check if user created the task and has edit permission
      if (task.createdBy == userId) {
        return permissions.editableByCreator;
      }
      
      return false;
    } catch (e) {
      Get.log('Failed to check edit permission for field $fieldName: $e');
      return false;
    }
  }

  /// Checks if user can delete a task
  Future<bool> canDeleteTask({
    required String userId,
    required Task task,
  }) async {
    if (!_isInitialized) {
      throw Exception('AccessControlService not initialized');
    }

    try {
      final user = await _userController.getUserById(userId);
      if (user == null) return false;
      
      // Admin can delete any task
      if (user['role'] == 'Admin') return true;
      
      // Librarian can delete tasks they created or are assigned to
      if (user['role'] == 'Librarian') {
        return task.createdById == userId || 
               task.assignedLibrarianId == userId;
      }
      
      // Other roles can only delete tasks they created
      return task.createdById == userId;
    } catch (e) {
      Get.log('Failed to check delete permission for task ${task.taskId}: $e');
      return false;
    }
  }

  /// Checks if user can archive a task
  Future<bool> canArchiveTask({
    required String userId,
    required Task task,
  }) async {
    if (!_isInitialized) {
      throw Exception('AccessControlService not initialized');
    }

    try {
      final user = await _userController.getUserById(userId);
      if (user == null) return false;
      
      // Admin and Librarian can archive tasks
      if (user['role'] == 'Admin' || user['role'] == 'Librarian') {
        return true;
      }
      
      // Task creator can archive their own tasks
      return task.createdBy == userId;
    } catch (e) {
      Get.log('Failed to check archive permission for task ${task.taskId}: $e');
      return false;
    }
  }

  /// Checks if user can export tasks
  Future<bool> canExportTasks(String userId) async {
    if (!_isInitialized) {
      throw Exception('AccessControlService not initialized');
    }

    try {
      final user = await _userController.getUserById(userId);
      if (user == null) return false;
      
      // Admin and Librarian can export tasks
      return user['role'] == 'Admin' || user['role'] == 'Librarian';
    } catch (e) {
      Get.log('Failed to check export permission for user $userId: $e');
      return false;
    }
  }

  /// Checks if user can perform bulk operations
  Future<bool> canPerformBulkOperations(String userId) async {
    if (!_isInitialized) {
      throw Exception('AccessControlService not initialized');
    }

    try {
      final user = await _userController.getUserById(userId);
      if (user == null) return false;
      
      // Only Admin and Librarian can perform bulk operations
      return user['role'] == 'Admin' || user['role'] == 'Librarian';
    } catch (e) {
      Get.log('Failed to check bulk operations permission for user $userId: $e');
      return false;
    }
  }

  /// Checks if user can manage attachments
  Future<bool> canManageAttachments({
    required String userId,
    required Task task,
  }) async {
    if (!_isInitialized) {
      throw Exception('AccessControlService not initialized');
    }

    try {
      final user = await _userController.getUserById(userId);
      if (user == null) return false;
      
      // Admin can manage all attachments
      if (user['role'] == 'Admin') return true;
      
      // Librarian can manage attachments for tasks they're assigned to
      if (user['role'] == 'Librarian' && task.assignedLibrarian == userId) {
        return true;
      }
      
      // Users can manage attachments for tasks they created or are assigned to
      return task.createdBy == userId || _isUserAssignedToTask(user, task);
    } catch (e) {
      Get.log('Failed to check attachment management permission: $e');
      return false;
    }
  }

  /// Checks if user can view version history
  Future<bool> canViewVersionHistory({
    required String userId,
    required Task task,
  }) async {
    if (!_isInitialized) {
      throw Exception('AccessControlService not initialized');
    }

    try {
      final user = await _userController.getUserById(userId);
      if (user == null) return false;
      
      // Admin and Librarian can view version history
      if (user['role'] == 'Admin' || user['role'] == 'Librarian') {
        return true;
      }
      
      // Users can view version history for tasks they're involved in
      return task.createdBy == userId || _isUserAssignedToTask(user, task);
    } catch (e) {
      Get.log('Failed to check version history permission: $e');
      return false;
    }
  }

  /// Gets filtered task data based on user permissions
  Future<Map<String, dynamic>> getFilteredTaskData({
    required String userId,
    required Task task,
  }) async {
    if (!_isInitialized) {
      throw Exception('AccessControlService not initialized');
    }

    try {
      final taskMap = task.toMap();
      final filteredMap = <String, dynamic>{};
      
      // Check each field permission
      for (final entry in taskMap.entries) {
        final canView = await canViewField(
          userId: userId,
          fieldName: entry.key,
          task: task,
        );
        
        if (canView) {
          filteredMap[entry.key] = entry.value;
        }
      }
      
      return filteredMap;
    } catch (e) {
      Get.log('Failed to get filtered task data: $e');
      return {};
    }
  }

  /// Gets field permissions from Firestore or default configuration
  Future<FieldPermissions> _getFieldPermissions(String fieldName) async {
    try {
      // Try to get custom permissions from Firestore
      final doc = await _firestore
          .collection('field_permissions')
          .doc(fieldName)
          .get();
      
      if (doc.exists && doc.data() != null) {
        return FieldPermissions.fromMap(doc.data()!);
      }
      
      // Return default permissions if not found
      return _getDefaultFieldPermissions(fieldName);
    } catch (e) {
      Get.log('Failed to get field permissions for $fieldName: $e');
      return _getDefaultFieldPermissions(fieldName);
    }
  }

  /// Gets default field permissions based on field name
  FieldPermissions _getDefaultFieldPermissions(String fieldName) {
    switch (fieldName) {
      case 'archiveReason':
      case 'archiveLocation':
      case 'archivedAt':
      case 'archivedBy':
        return FieldPermissions(
          fieldName: fieldName,
          allowedRoles: ['Admin', 'Librarian'],
          editableByRoles: ['Admin', 'Librarian'],
          allowAssignedUsers: false,
          allowCreator: false,
          editableByAssignedUsers: false,
          editableByCreator: false,
          isEditable: true,
        );
      
      case 'assignedLibrarian':
        return FieldPermissions(
          fieldName: fieldName,
          allowedRoles: ['Admin', 'Librarian'],
          editableByRoles: ['Admin', 'Librarian'],
          allowAssignedUsers: true,
          allowCreator: true,
          editableByAssignedUsers: false,
          editableByCreator: false,
          isEditable: true,
        );
      
      case 'attachmentUrls':
      case 'attachmentNames':
      case 'attachmentTypes':
      case 'attachmentSizes':
      case 'lastAttachmentAdded':
        return FieldPermissions(
          fieldName: fieldName,
          allowedRoles: ['Admin', 'Librarian', 'Reporter', 'Cameraman', 'Driver'],
          editableByRoles: ['Admin', 'Librarian'],
          allowAssignedUsers: true,
          allowCreator: true,
          editableByAssignedUsers: true,
          editableByCreator: true,
          isEditable: true,
        );
      
      default:
        // Default permissions for other fields
        return FieldPermissions(
          fieldName: fieldName,
          allowedRoles: ['Admin', 'Librarian', 'Reporter', 'Cameraman', 'Driver'],
          editableByRoles: ['Admin', 'Librarian', 'Reporter'],
          allowAssignedUsers: true,
          allowCreator: true,
          editableByAssignedUsers: true,
          editableByCreator: true,
          isEditable: true,
        );
    }
  }

  /// Checks if user is assigned to the task in any role
  bool _isUserAssignedToTask(Map<String, dynamic> user, Task task) {
    return task.assignedReporter == user['id'] ||
            task.assignedCameraman == user['id'] ||
            task.assignedDriver == user['id'] ||
            task.assignedLibrarian == user['id'];
  }

  /// Creates or updates field permissions
  Future<void> setFieldPermissions(FieldPermissions permissions) async {
    if (!_isInitialized) {
      throw Exception('AccessControlService not initialized');
    }

    try {
      await _firestore
          .collection('field_permissions')
          .doc(permissions.fieldName)
          .set(permissions.toMap());
      
      Get.log('Successfully updated permissions for field: ${permissions.fieldName}');
    } catch (e) {
      Get.log('Failed to set field permissions: $e');
      rethrow;
    }
  }

  /// Gets all field permissions
  Future<List<FieldPermissions>> getAllFieldPermissions() async {
    if (!_isInitialized) {
      throw Exception('AccessControlService not initialized');
    }

    try {
      final querySnapshot = await _firestore
          .collection('field_permissions')
          .get();
      
      return querySnapshot.docs
          .map((doc) => FieldPermissions.fromMap(doc.data()))
          .toList();
    } catch (e) {
      Get.log('Failed to get all field permissions: $e');
      return [];
    }
  }
}

/// Represents field-level permissions
class FieldPermissions {
  final String fieldName;
  final List<String> allowedRoles;
  final List<String> editableByRoles;
  final bool allowAssignedUsers;
  final bool allowCreator;
  final bool editableByAssignedUsers;
  final bool editableByCreator;
  final bool isEditable;

  FieldPermissions({
    required this.fieldName,
    required this.allowedRoles,
    required this.editableByRoles,
    required this.allowAssignedUsers,
    required this.allowCreator,
    required this.editableByAssignedUsers,
    required this.editableByCreator,
    required this.isEditable,
  });

  Map<String, dynamic> toMap() {
    return {
      'fieldName': fieldName,
      'allowedRoles': allowedRoles,
      'editableByRoles': editableByRoles,
      'allowAssignedUsers': allowAssignedUsers,
      'allowCreator': allowCreator,
      'editableByAssignedUsers': editableByAssignedUsers,
      'editableByCreator': editableByCreator,
      'isEditable': isEditable,
    };
  }

  factory FieldPermissions.fromMap(Map<String, dynamic> map) {
    return FieldPermissions(
      fieldName: map['fieldName'] ?? '',
      allowedRoles: List<String>.from(map['allowedRoles'] ?? []),
      editableByRoles: List<String>.from(map['editableByRoles'] ?? []),
      allowAssignedUsers: map['allowAssignedUsers'] ?? false,
      allowCreator: map['allowCreator'] ?? false,
      editableByAssignedUsers: map['editableByAssignedUsers'] ?? false,
      editableByCreator: map['editableByCreator'] ?? false,
      isEditable: map['isEditable'] ?? true,
    );
  }
}