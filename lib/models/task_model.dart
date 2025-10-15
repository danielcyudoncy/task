// models/task_model.dart
import 'dart:core';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:task/models/report_completion_info.dart';

DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}

class Task {
  int? id; // SQLite auto-increment primary key

  late String taskId;
  late String title;
  late String description;
  late String createdBy;
  String? createdByName;
  String? assignedReporter;
  String? assignedCameraman;
  String? assignedDriver;
  String? assignedLibrarian;
  late String status;
  List<String> comments = [];
  late DateTime timestamp;
  String? assignedTo;
  DateTime? assignmentTimestamp;
  late String createdById;
  String? assignedReporterId;
  String? assignedCameramanId;
  String? assignedDriverId;
  String? assignedLibrarianId;
  String? creatorAvatar;
  String? category;
  List<String> tags = [];
  DateTime? dueDate;
  String? priority;
  DateTime? lastModified;
  String? syncStatus;

  // Approval system fields
  String? approvalStatus; // 'pending', 'approved', 'rejected'
  String? approvedBy; // Admin user ID who approved/rejected
  DateTime? approvalTimestamp;
  String? approvalReason; // Optional reason for approval/rejection

  // Media & Document Attachments
  List<String> attachmentUrls = []; // URLs of uploaded files
  List<String> attachmentNames = []; // Original file names
  List<String> attachmentTypes =
      []; // File types (image, document, video, etc.)
  List<int> attachmentSizes = []; // File sizes in bytes
  DateTime? lastAttachmentAdded;

  // Archive related fields
  bool get isArchived => status.toLowerCase() == 'archived';

  // Approval related fields
  bool get isApproved => approvalStatus?.toLowerCase() == 'approved';
  bool get isRejected => approvalStatus?.toLowerCase() == 'rejected';
  bool get isPendingApproval =>
      approvalStatus?.toLowerCase() == 'pending' || approvalStatus == null;
  bool get canBeAssigned => isApproved; // Only approved tasks can be assigned

  // Helper method to get all assigned user IDs
  List<String> get assignedUserIds {
    List<String> userIds = [];
    if (assignedReporterId != null && assignedReporterId!.isNotEmpty) {
      userIds.add(assignedReporterId!);
    }
    if (assignedCameramanId != null && assignedCameramanId!.isNotEmpty) {
      userIds.add(assignedCameramanId!);
    }
    if (assignedDriverId != null && assignedDriverId!.isNotEmpty) {
      userIds.add(assignedDriverId!);
    }
    if (assignedLibrarianId != null && assignedLibrarianId!.isNotEmpty) {
      userIds.add(assignedLibrarianId!);
    }
    return userIds;
  }

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

  DateTime? archivedAt;
  String? archivedBy;
  String? archiveReason;
  String?
      archiveLocation; // Physical or digital location where the task is archived

  // Individual user completion tracking
  List<String> completedByUserIds =
      []; // List of user IDs who have marked this task as complete
  Map<String, DateTime> userCompletionTimestamps =
      {}; // Track when each user completed the task

  // Report completion tracking
  Map<String, ReportCompletionInfo> reportCompletionInfo =
      {}; // Reporter ID -> Completion Info

  // Task review system
  Map<String, String> taskReviews = {}; // Reviewer ID -> Review comment
  Map<String, double> taskRatings = {}; // Reviewer ID -> Rating (1-5)
  Map<String, DateTime> reviewTimestamps = {}; // When each review was submitted
  Map<String, String> reviewerRoles = {}; // Role of each reviewer

  Task()
      : taskId = '',
        title = '',
        description = '',
        createdBy = '',
        status = '',
        timestamp = DateTime.now(),
        createdById = '',
        lastModified = DateTime.now(),
        syncStatus = 'pending',
        approvalStatus = 'pending',
        attachmentUrls = [],
        attachmentNames = [],
        attachmentTypes = [],
        attachmentSizes = [],
        completedByUserIds = [],
        userCompletionTimestamps = {},
        taskReviews = {},
        taskRatings = {},
        reviewTimestamps = {},
        reviewerRoles = {};

  Task.full(
      this.taskId,
      this.title,
      this.description,
      this.createdBy,
      this.assignedReporter,
      this.assignedCameraman,
      this.assignedDriver,
      this.assignedLibrarian,
      this.status,
      List<String>? comments,
      this.timestamp,
      this.assignedTo,
      this.assignmentTimestamp,
      this.createdById,
      this.assignedReporterId,
      this.assignedCameramanId,
      this.assignedDriverId,
      this.assignedLibrarianId,
      this.creatorAvatar,
      this.category,
      List<String>? tags,
      this.dueDate,
      this.priority,
      {this.lastModified,
      this.syncStatus,
      this.approvalStatus = 'pending',
      this.approvedBy,
      this.approvalTimestamp,
      this.approvalReason,
      this.archivedAt,
      this.archivedBy,
      this.archiveReason,
      this.archiveLocation,
      List<String>? attachmentUrls,
      List<String>? attachmentNames,
      List<String>? attachmentTypes,
      List<int>? attachmentSizes,
      this.lastAttachmentAdded,
      List<String>? completedByUserIds,
      Map<String, DateTime>? userCompletionTimestamps,
      Map<String, String>? taskReviews,
      Map<String, double>? taskRatings,
      Map<String, DateTime>? reviewTimestamps,
      Map<String, String>? reviewerRoles,
      Map<String, ReportCompletionInfo>? reportCompletionInfo,
      this.createdByName}) {
    this.taskReviews = taskReviews ?? {};
    this.taskRatings = taskRatings ?? {};
    this.reviewTimestamps = reviewTimestamps ?? {};
    this.reviewerRoles = reviewerRoles ?? {};
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    // debugPrint('Task.fromMap called with: $map');
    String taskId = map['taskId'] ?? map['id']?.toString() ?? '';
    debugPrint(
        'fromMap creator data: createdBy=${map['createdBy']}, createdByName=${map['createdByName']}');

    // Parse reportCompletionInfo
    Map<String, ReportCompletionInfo> reportCompletionInfo = {};
    if (map['reportCompletionInfo'] != null) {
      try {
        if (map['reportCompletionInfo'] is String) {
          final decoded =
              jsonDecode(map['reportCompletionInfo']) as Map<String, dynamic>;
          decoded.forEach((key, value) {
            if (value is Map<String, dynamic>) {
              reportCompletionInfo[key] = ReportCompletionInfo.fromMap(value);
            }
          });
        } else if (map['reportCompletionInfo'] is Map) {
          (map['reportCompletionInfo'] as Map<String, dynamic>)
              .forEach((key, value) {
            if (value is Map<String, dynamic>) {
              reportCompletionInfo[key] = ReportCompletionInfo.fromMap(value);
            }
          });
        }
      } catch (e) {
        debugPrint('Error parsing reportCompletionInfo: $e');
      }
    }

    final task = Task.full(
        taskId,
        map['title'] ?? '',
        map['description'] ?? '',
        map['createdBy'] ?? 'Unknown',
        map['assignedReporterName'] ?? map['assignedReporter'],
        map['assignedCameramanName'] ?? map['assignedCameraman'],
        map['assignedDriverName'] ?? map['assignedDriver'],
        map['assignedLibrarian'],
        map['status'] ?? '',
        _parseStringList(map['comments']),
        parseDate(map['timestamp']) ?? DateTime.now(),
        map['assignedTo'],
        parseDate(map['assignmentTimestamp']),
        map['createdById'] ??
            map['createdBy'] ??
            '', // Use createdById field for user ID
        map['assignedReporterId'],
        map['assignedCameramanId'],
        map['assignedDriverId'],
        map['assignedLibrarianId'],
        map['creatorAvatar'],
        map['category'],
        _parseStringList(map['tags']),
        parseDate(map['dueDate']),
        map['priority'],
        lastModified: parseDate(map['lastModified']),
        syncStatus: map['syncStatus'],
        approvalStatus: map['approvalStatus'] ?? 'pending',
        approvedBy: map['approvedBy'],
        approvalTimestamp: parseDate(map['approvalTimestamp']),
        approvalReason: map['approvalReason'],
        archivedAt: parseDate(map['archivedAt']),
        archivedBy: map['archivedBy'],
        archiveReason: map['archiveReason'],
        archiveLocation: map['archiveLocation'],
        attachmentUrls: _parseStringList(map['attachmentUrls']),
        attachmentNames: _parseStringList(map['attachmentNames']),
        attachmentTypes: _parseStringList(map['attachmentTypes']),
        attachmentSizes: _parseIntList(map['attachmentSizes']),
        lastAttachmentAdded: parseDate(map['lastAttachmentAdded']),
        completedByUserIds: _parseStringList(map['completedByUserIds']),
        createdByName: map['createdByName']);

    // Parse and set other maps
    task.reportCompletionInfo = reportCompletionInfo;
    task.userCompletionTimestamps =
        _parseTimestampMap(map['userCompletionTimestamps']);

    // Parse review data
    if (map['taskReviews'] != null) {
      task.taskReviews =
          Map<String, String>.from(jsonDecode(map['taskReviews']));
    }
    if (map['taskRatings'] != null) {
      task.taskRatings =
          (jsonDecode(map['taskRatings']) as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, double.parse(v.toString())));
    }
    if (map['reviewTimestamps'] != null) {
      task.reviewTimestamps = (jsonDecode(map['reviewTimestamps'])
              as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, DateTime.fromMillisecondsSinceEpoch(v)));
    }
    if (map['reviewerRoles'] != null) {
      task.reviewerRoles =
          Map<String, String>.from(jsonDecode(map['reviewerRoles']));
    }

    return task;
  }

  // Create a copy of the task with updated fields
  Task copyWith({
    String? taskId,
    String? title,
    String? description,
    String? createdBy,
    String? assignedReporter,
    String? assignedCameraman,
    String? assignedDriver,
    String? assignedLibrarian,
    String? status,
    List<String>? comments,
    DateTime? timestamp,
    String? assignedTo,
    DateTime? assignmentTimestamp,
    String? createdById,
    String? assignedReporterId,
    String? assignedCameramanId,
    String? assignedDriverId,
    String? assignedLibrarianId,
    String? creatorAvatar,
    String? category,
    List<String>? tags,
    DateTime? dueDate,
    String? priority,
    DateTime? lastModified,
    String? syncStatus,
    String? approvalStatus,
    String? approvedBy,
    DateTime? approvalTimestamp,
    String? approvalReason,
    DateTime? archivedAt,
    String? archivedBy,
    String? archiveReason,
    String? archiveLocation,
    List<String>? attachmentUrls,
    List<String>? attachmentNames,
    List<String>? attachmentTypes,
    List<int>? attachmentSizes,
    DateTime? lastAttachmentAdded,
    List<String>? completedByUserIds,
    Map<String, DateTime>? userCompletionTimestamps,
    Map<String, String>? taskReviews,
    Map<String, double>? taskRatings,
    Map<String, DateTime>? reviewTimestamps,
    Map<String, String>? reviewerRoles,
    Map<String, ReportCompletionInfo>? reportCompletionInfo,
  }) {
    return Task.full(
      taskId ?? this.taskId,
      title ?? this.title,
      description ?? this.description,
      createdBy ?? this.createdBy,
      assignedReporter ?? this.assignedReporter,
      assignedCameraman ?? this.assignedCameraman,
      assignedDriver ?? this.assignedDriver,
      assignedLibrarian ?? this.assignedLibrarian,
      status ?? this.status,
      comments ?? List.from(this.comments),
      timestamp ?? this.timestamp,
      assignedTo ?? this.assignedTo,
      assignmentTimestamp ?? this.assignmentTimestamp,
      createdById ?? this.createdById,
      assignedReporterId ?? this.assignedReporterId,
      assignedCameramanId ?? this.assignedCameramanId,
      assignedDriverId ?? this.assignedDriverId,
      assignedLibrarianId ?? this.assignedLibrarianId,
      creatorAvatar ?? this.creatorAvatar,
      category ?? this.category,
      tags ?? List.from(this.tags),
      dueDate ?? this.dueDate,
      priority ?? this.priority,
      lastModified: lastModified ?? this.lastModified ?? DateTime.now(),
      syncStatus: syncStatus ?? this.syncStatus ?? 'pending',
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedBy: approvedBy ?? this.approvedBy,
      approvalTimestamp: approvalTimestamp ?? this.approvalTimestamp,
      approvalReason: approvalReason ?? this.approvalReason,
      archivedAt: archivedAt ?? this.archivedAt,
      archivedBy: archivedBy ?? this.archivedBy,
      archiveReason: archiveReason ?? this.archiveReason,
      archiveLocation: archiveLocation ?? this.archiveLocation,
      attachmentUrls: attachmentUrls ?? List.from(this.attachmentUrls),
      attachmentNames: attachmentNames ?? List.from(this.attachmentNames),
      attachmentTypes: attachmentTypes ?? List.from(this.attachmentTypes),
      attachmentSizes: attachmentSizes ?? List.from(this.attachmentSizes),
      lastAttachmentAdded: lastAttachmentAdded ?? this.lastAttachmentAdded,
      completedByUserIds:
          completedByUserIds ?? List.from(this.completedByUserIds),
      userCompletionTimestamps:
          userCompletionTimestamps ?? Map.from(this.userCompletionTimestamps),
      taskReviews: taskReviews ?? Map.from(this.taskReviews),
      taskRatings: taskRatings ?? Map.from(this.taskRatings),
      reviewTimestamps: reviewTimestamps ?? Map.from(this.reviewTimestamps),
      reviewerRoles: reviewerRoles ?? Map.from(this.reviewerRoles),
      reportCompletionInfo:
          reportCompletionInfo ?? Map.from(this.reportCompletionInfo),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'assignedReporter': assignedReporter,
      'assignedCameraman': assignedCameraman,
      'assignedDriver': assignedDriver,
      'assignedLibrarian': assignedLibrarian,
      'status': status,
      'comments': jsonEncode(comments),
      'timestamp': timestamp.millisecondsSinceEpoch,
      'assignedTo': assignedTo,
      'assignmentTimestamp': assignmentTimestamp?.millisecondsSinceEpoch,
      'createdById': createdById,
      'assignedReporterId': assignedReporterId,
      'reportCompletionInfo': jsonEncode(Map.fromEntries(reportCompletionInfo
          .entries
          .map((e) => MapEntry(e.key, e.value.toMap())))),
      'assignedCameramanId': assignedCameramanId,
      'assignedDriverId': assignedDriverId,
      'assignedLibrarianId': assignedLibrarianId,
      'creatorAvatar': creatorAvatar,
      'category': category,
      'tags': jsonEncode(tags),
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'priority': priority,
      'lastModified': (lastModified ?? DateTime.now()).millisecondsSinceEpoch,
      'syncStatus': syncStatus,
      'approvalStatus': approvalStatus,
      'approvedBy': approvedBy,
      'approvalTimestamp': approvalTimestamp?.millisecondsSinceEpoch,
      'approvalReason': approvalReason,
      'archivedAt': archivedAt?.millisecondsSinceEpoch,
      'archivedBy': archivedBy,
      'archiveReason': archiveReason,
      'archiveLocation': archiveLocation,
      'attachmentUrls': jsonEncode(attachmentUrls),
      'attachmentNames': jsonEncode(attachmentNames),
      'attachmentTypes': jsonEncode(attachmentTypes),
      'attachmentSizes': jsonEncode(attachmentSizes),
      'lastAttachmentAdded': lastAttachmentAdded?.millisecondsSinceEpoch,
      'completedByUserIds': jsonEncode(completedByUserIds),
      'taskReviews': jsonEncode(taskReviews),
      'taskRatings':
          jsonEncode(taskRatings.map((k, v) => MapEntry(k, v.toString()))),
      'reviewTimestamps': jsonEncode(reviewTimestamps
          .map((k, v) => MapEntry(k, v.millisecondsSinceEpoch))),
      'reviewerRoles': jsonEncode(reviewerRoles),
      'userCompletionTimestamps': jsonEncode(userCompletionTimestamps
          .map((key, value) => MapEntry(key, value.millisecondsSinceEpoch))),
    }..removeWhere((key, value) => value == null);
  }

  // Helper methods for SQLite data parsing
  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is String) {
      try {
        return List<String>.from(jsonDecode(value));
      } catch (e) {
        return [];
      }
    }
    if (value is List) return List<String>.from(value);
    return [];
  }

  static List<int> _parseIntList(dynamic value) {
    if (value == null) return [];
    if (value is String) {
      try {
        return List<int>.from(jsonDecode(value));
      } catch (e) {
        return [];
      }
    }
    if (value is List) return List<int>.from(value);
    return [];
  }

  static Map<String, DateTime> _parseTimestampMap(dynamic value) {
    if (value == null) return {};
    if (value is String) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(value);
        return decoded.map((key, value) =>
            MapEntry(key, DateTime.fromMillisecondsSinceEpoch(value as int)));
      } catch (e) {
        return {};
      }
    }
    if (value is Map) {
      return Map<String, DateTime>.from(value.map((key, value) =>
          MapEntry(key.toString(), parseDate(value) ?? DateTime.now())));
    }
    return {};
  }

  // Permission methods for task creators
  /// Checks if the given user is the creator of this task
  bool isCreator(String userId) {
    return userId == createdById;
  }

  /// Checks if the given user can edit this task
  bool canEdit(String userId) {
    return isCreator(userId);
  }

  /// Checks if the given user can delete this task
  bool canDelete(String userId) {
    return isCreator(userId);
  }

  /// Checks if the given user can mark this task as complete
  bool canMarkComplete(String userId) {
    // Creator can always mark their own task as complete
    if (isCreator(userId)) return true;

    // Assigned users can also mark the task as complete
    return assignedUserIds.contains(userId);
  }

  /// Marks the task as complete for the given user
  void markComplete(String userId) {
    if (!canMarkComplete(userId)) {
      throw Exception(
          'User does not have permission to mark this task as complete');
    }

    // Add user to completed list if not already there
    if (!completedByUserIds.contains(userId)) {
      completedByUserIds.add(userId);
      userCompletionTimestamps[userId] = DateTime.now();

      // Update the last modified timestamp
      lastModified = DateTime.now();
    }
  }

  /// Unmarks the task as complete for the given user
  void unmarkComplete(String userId) {
    if (!canMarkComplete(userId)) {
      throw Exception(
          'User does not have permission to unmark this task as complete');
    }

    // Remove user from completed list
    completedByUserIds.remove(userId);
    userCompletionTimestamps.remove(userId);

    // Update the last modified timestamp
    lastModified = DateTime.now();
  }

  // Review system methods
  bool canUserReview(String userId, String userRole) {
    // Only allow one review per user
    if (taskReviews.containsKey(userId)) return false;

    // Check if user has appropriate role
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

  // Add or update a review
  void addReview(
      String reviewerId, String reviewerRole, String comment, double rating) {
    if (!canUserReview(reviewerId, reviewerRole)) {
      throw Exception('User does not have permission to review this task');
    }

    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be between 1 and 5');
    }

    taskReviews[reviewerId] = comment;
    taskRatings[reviewerId] = rating;
    reviewTimestamps[reviewerId] = DateTime.now();
    reviewerRoles[reviewerId] = reviewerRole;
  }

  // Remove a review
  void removeReview(String reviewerId) {
    taskReviews.remove(reviewerId);
    taskRatings.remove(reviewerId);
    reviewTimestamps.remove(reviewerId);
    reviewerRoles.remove(reviewerId);
  }

  // Get average rating
  double get averageRating {
    if (taskRatings.isEmpty) return 0;
    final sum = taskRatings.values.reduce((a, b) => a + b);
    return sum / taskRatings.length;
  }

  // Calculate performance impact
  double calculatePerformanceImpact() {
    if (taskRatings.isEmpty) return 0;

    // Weigh impact by reviewer roles
    double weightedImpact = 0;
    int totalWeight = 0;

    for (var reviewerId in taskRatings.keys) {
      int weight = switch (reviewerRoles[reviewerId]?.toLowerCase()) {
        'admin' => 4,
        'head_of_department' => 3,
        'head_of_unit' => 2,
        'assignment_editor' => 2,
        _ => 1,
      };

      weightedImpact += (taskRatings[reviewerId]! - 3) / 2 * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? weightedImpact / totalWeight : 0;
  }

  Map<String, dynamic> toMapWithUserInfo(Map<String, String> userNameCache,
      [Map<String, String>? userAvatarCache]) {
    return {
      'taskId': taskId,
      'title': title,
      'description': description,
      'createdBy': createdById,
      'creatorName': userNameCache[createdById] ?? createdBy,
      'creatorAvatar': creatorAvatar ?? userAvatarCache?[createdById] ?? '',
      'status': status,
      'comments': comments,
      'timestamp': timestamp,
      'category': category,
      'tags': tags,
      'dueDate': dueDate,
      'priority': priority,
    };
  }
}
