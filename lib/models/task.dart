// models/task.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task/models/task_core.dart';
import 'package:task/models/task_metadata.dart';
import 'package:task/models/report_completion_info.dart';

DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Combined Task class using composition of TaskCore and TaskMetadata
/// This maintains backward compatibility while improving performance
class Task {
  final TaskCore core;
  final TaskMetadata? metadata;

  Task({
    required this.core,
    this.metadata,
  });

  // Convenience getters for backward compatibility
  String get taskId => core.taskId;
  String get title => core.title;
  String get description => core.description;
  String get createdBy => core.createdBy;
  String get createdById => core.createdBy;
  String? get createdByName => core.createdByName;
  String get status => core.status;
  DateTime get timestamp => core.timestamp;
  String? get priority => core.priority;
  DateTime? get dueDate => core.dueDate;
  String? get category => core.category;
  List<String> get tags => core.tags;

  // Setters for backward compatibility - Note: This creates a new Task instance
  Task withCreatedByName(String? name) {
    return Task(
      core: core.copyWith(createdByName: name),
      metadata: metadata,
    );
  }

  // Metadata getters with null safety
  String? get assignedReporter => metadata?.assignedReporter;
  String? get assignedCameraman => metadata?.assignedCameraman;
  String? get assignedDriver => metadata?.assignedDriver;
  String? get assignedLibrarian => metadata?.assignedLibrarian;
  String? get assignedTo => metadata?.assignedTo;
  DateTime? get assignmentTimestamp => metadata?.assignmentTimestamp;
  String? get assignedReporterId => metadata?.assignedReporterId;
  String? get assignedCameramanId => metadata?.assignedCameramanId;
  String? get assignedDriverId => metadata?.assignedDriverId;
  String? get assignedLibrarianId => metadata?.assignedLibrarianId;
  String? get creatorAvatar => metadata?.creatorAvatar;
  List<String> get comments => metadata?.comments ?? [];
  DateTime? get lastModified => metadata?.lastModified;
  String? get syncStatus => metadata?.syncStatus;
  String? get approvalStatus => metadata?.approvalStatus ?? 'pending';
  String? get approvedBy => metadata?.approvedBy;
  DateTime? get approvalTimestamp => metadata?.approvalTimestamp;
  String? get approvalReason => metadata?.approvalReason;
  DateTime? get archivedAt => metadata?.archivedAt;
  String? get archivedBy => metadata?.archivedBy;
  String? get archiveReason => metadata?.archiveReason;
  String? get archiveLocation => metadata?.archiveLocation;
  List<String> get attachmentUrls => metadata?.attachmentUrls ?? [];
  List<String> get attachmentNames => metadata?.attachmentNames ?? [];
  List<String> get attachmentTypes => metadata?.attachmentTypes ?? [];
  List<int> get attachmentSizes => metadata?.attachmentSizes ?? [];
  DateTime? get lastAttachmentAdded => metadata?.lastAttachmentAdded;
  List<String> get completedByUserIds => metadata?.completedByUserIds ?? [];
  Map<String, DateTime> get userCompletionTimestamps =>
      metadata?.userCompletionTimestamps ?? {};
  Map<String, ReportCompletionInfo> get reportCompletionInfo =>
      metadata?.reportCompletionInfo ?? {};
  Map<String, String> get taskReviews => metadata?.taskReviews ?? {};
  Map<String, double> get taskRatings => metadata?.taskRatings ?? {};
  Map<String, DateTime> get reviewTimestamps =>
      metadata?.reviewTimestamps ?? {};
  Map<String, String> get reviewerRoles => metadata?.reviewerRoles ?? {};

  // Computed properties
  bool get isCompleted => core.isCompleted;
  bool get isPending => core.isPending;
  bool get isInProgress => core.isInProgress;
  bool get isOverdue => core.isOverdue;
  bool get isApproved => metadata?.isApproved ?? false;
  bool get isRejected => metadata?.isRejected ?? false;
  bool get isPendingApproval => metadata?.isPendingApproval ?? true;
  bool get canBeAssigned => metadata?.canBeAssigned ?? false;
  bool get isArchived => metadata?.isArchived ?? false;

  // Helper method to get all assigned user IDs
  List<String> get assignedUserIds => metadata?.assignedUserIds ?? [];

  // Helper method to get all assigned user IDs including legacy assignedTo field
  List<String> get allAssignedUserIds {
    List<String> userIds = List.from(assignedUserIds);
    if (assignedTo != null &&
        assignedTo!.isNotEmpty &&
        !userIds.contains(assignedTo)) {
      userIds.add(assignedTo!);
    }
    return userIds;
  }

  // Helper method to check if all assigned users have completed the task
  bool get isCompletedByAllAssignedUsers {
    final assignedUsers = assignedUserIds;
    if (assignedUsers.isEmpty) return false;

    // Check if all assigned users have marked the task as complete
    return assignedUsers.every((userId) => completedByUserIds.contains(userId));
  }

  // Get average rating
  double get averageRating => metadata?.averageRating ?? 0;

  factory Task.fromMap(Map<String, dynamic> map) {
    // Split the map into core and metadata parts
    final coreMap = Map<String, dynamic>.from(map)
      ..remove('taskId'); // Keep taskId for core
    coreMap['taskId'] = map['taskId'];
  
    final core = TaskCore.fromMap(coreMap);
  
    // Extract metadata fields
    final metadataMap = <String, dynamic>{};
    final metadataFields = [
      'assignedReporter',
      'assignedReporterName',
      'assignedCameraman',
      'assignedCameramanName',
      'assignedDriver',
      'assignedDriverName',
      'assignedLibrarian',
      'assignedTo',
      'assignmentTimestamp',
      'assignedReporterId',
      'assignedCameramanId',
      'assignedDriverId',
      'assignedLibrarianId',
      'creatorAvatar',
      'comments',
      'lastModified',
      'syncStatus',
      'approvalStatus',
      'approvedBy',
      'approvalTimestamp',
      'approvalReason',
      'archivedAt',
      'archivedBy',
      'archiveReason',
      'archiveLocation',
      'attachmentUrls',
      'attachmentNames',
      'attachmentTypes',
      'attachmentSizes',
      'lastAttachmentAdded',
      'completedByUserIds',
      'userCompletionTimestamps',
      'reportCompletionInfo',
      'taskReviews',
      'taskRatings',
      'reviewTimestamps',
      'reviewerRoles',
    ];
  
    for (final field in metadataFields) {
      if (map.containsKey(field)) {
        metadataMap[field] = map[field];
      }
    }
  
    final metadata =
        metadataMap.isNotEmpty ? TaskMetadata.fromMap(metadataMap) : null;
  
    return Task(core: core, metadata: metadata);
  }

  Task copyWith({
    TaskCore? core,
    TaskMetadata? metadata,
  }) {
    return Task(
      core: core ?? this.core,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    final map = core.toMap();
    if (metadata != null) {
      map.addAll(metadata!.toMap());
    }
    return map;
  }


  // Permission methods for task creators
  bool isCreator(String userId) {
    return userId == createdBy;
  }

  bool canEdit(String userId) {
    return isCreator(userId);
  }

  bool canDelete(String userId) {
    return isCreator(userId);
  }

  bool canMarkComplete(String userId) {
    if (isCreator(userId)) return true;
    return assignedUserIds.contains(userId);
  }

  // Review system methods
  bool canUserReview(String userId, String userRole) {
    if (metadata?.taskReviews.containsKey(userId) ?? false) return false;

    switch (userRole.toLowerCase()) {
      case 'admin':
      case 'assignment_editor':
      case 'head_of_department':
      case 'head_of_unit':
        return true;
      default:
        return false;
    }
  }

  void addReview(
      String reviewerId, String reviewerRole, String comment, double rating) {
    if (!canUserReview(reviewerId, reviewerRole)) {
      throw Exception('User does not have permission to review this task');
    }

    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be between 1 and 5');
    }

    final updatedReviews =
        Map<String, String>.from(metadata?.taskReviews ?? {});
    final updatedRatings =
        Map<String, double>.from(metadata?.taskRatings ?? {});
    final updatedTimestamps =
        Map<String, DateTime>.from(metadata?.reviewTimestamps ?? {});
    final updatedRoles =
        Map<String, String>.from(metadata?.reviewerRoles ?? {});

    updatedReviews[reviewerId] = comment;
    updatedRatings[reviewerId] = rating;
    updatedTimestamps[reviewerId] = DateTime.now();
    updatedRoles[reviewerId] = reviewerRole;

    // Note: This method creates updated metadata but doesn't modify the current task
    // The calling code should create a new Task with the updated metadata
  }

  void removeReview(String reviewerId) {
    final updatedReviews =
        Map<String, String>.from(metadata?.taskReviews ?? {});
    final updatedRatings =
        Map<String, double>.from(metadata?.taskRatings ?? {});
    final updatedTimestamps =
        Map<String, DateTime>.from(metadata?.reviewTimestamps ?? {});
    final updatedRoles =
        Map<String, String>.from(metadata?.reviewerRoles ?? {});

    updatedReviews.remove(reviewerId);
    updatedRatings.remove(reviewerId);
    updatedTimestamps.remove(reviewerId);
    updatedRoles.remove(reviewerId);

    // Note: This method creates updated metadata but doesn't modify the current task
    // The calling code should create a new Task with the updated metadata
  }

  @override
  String toString() {
    return 'Task(title: $title, status: $status, hasMetadata: ${metadata != null})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task && other.taskId == taskId;
  }

  @override
  int get hashCode => taskId.hashCode;
}
