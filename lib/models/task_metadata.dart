// models/task_metadata.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task/models/report_completion_info.dart';

DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Extended task metadata - fields that can be lazy-loaded when needed
class TaskMetadata {
  final String? assignedReporter;
  final String? assignedCameraman;
  final String? assignedDriver;
  final String? assignedLibrarian;
  final String? assignedTo;
  final DateTime? assignmentTimestamp;
  final String? assignedReporterId;
  final String? assignedCameramanId;
  final String? assignedDriverId;
  final String? assignedLibrarianId;
  final String? creatorAvatar;
  final List<String> comments;
  final DateTime? lastModified;
  final String? syncStatus;

  // Approval system fields
  final String? approvalStatus;
  final String? approvedBy;
  final DateTime? approvalTimestamp;
  final String? approvalReason;

  // Archive related fields
  final DateTime? archivedAt;
  final String? archivedBy;
  final String? archiveReason;
  final String? archiveLocation;

  // Media & Document Attachments
  final List<String> attachmentUrls;
  final List<String> attachmentNames;
  final List<String> attachmentTypes;
  final List<int> attachmentSizes;
  final DateTime? lastAttachmentAdded;

  // Individual user completion tracking
  final List<String> completedByUserIds;
  final Map<String, DateTime> userCompletionTimestamps;

  // Report completion tracking
  final Map<String, ReportCompletionInfo> reportCompletionInfo;

  // Task review system
  final Map<String, String> taskReviews;
  final Map<String, double> taskRatings;
  final Map<String, DateTime> reviewTimestamps;
  final Map<String, String> reviewerRoles;

  // Computed properties
  bool get isApproved => approvalStatus?.toLowerCase() == 'approved';
  bool get isRejected => approvalStatus?.toLowerCase() == 'rejected';
  bool get isPendingApproval =>
      approvalStatus?.toLowerCase() == 'pending' || approvalStatus == null;
  bool get canBeAssigned => isApproved;
  bool get isArchived => archivedAt != null;

  TaskMetadata({
    this.assignedReporter,
    this.assignedCameraman,
    this.assignedDriver,
    this.assignedLibrarian,
    this.assignedTo,
    this.assignmentTimestamp,
    this.assignedReporterId,
    this.assignedCameramanId,
    this.assignedDriverId,
    this.assignedLibrarianId,
    this.creatorAvatar,
    this.comments = const [],
    this.lastModified,
    this.syncStatus,
    this.approvalStatus,
    this.approvedBy,
    this.approvalTimestamp,
    this.approvalReason,
    this.archivedAt,
    this.archivedBy,
    this.archiveReason,
    this.archiveLocation,
    this.attachmentUrls = const [],
    this.attachmentNames = const [],
    this.attachmentTypes = const [],
    this.attachmentSizes = const [],
    this.lastAttachmentAdded,
    this.completedByUserIds = const [],
    this.userCompletionTimestamps = const {},
    this.reportCompletionInfo = const {},
    this.taskReviews = const {},
    this.taskRatings = const {},
    this.reviewTimestamps = const {},
    this.reviewerRoles = const {},
  });

  factory TaskMetadata.fromMap(Map<String, dynamic> map) {
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

    return TaskMetadata(
      assignedReporter: map['assignedReporterName'] ?? map['assignedReporter'],
      assignedCameraman:
          map['assignedCameramanName'] ?? map['assignedCameraman'],
      assignedDriver: map['assignedDriverName'] ?? map['assignedDriver'],
      assignedLibrarian: map['assignedLibrarian'],
      assignedTo: map['assignedTo'],
      assignmentTimestamp: parseDate(map['assignmentTimestamp']),
      assignedReporterId: map['assignedReporterId'],
      assignedCameramanId: map['assignedCameramanId'],
      assignedDriverId: map['assignedDriverId'],
      assignedLibrarianId: map['assignedLibrarianId'],
      creatorAvatar: map['creatorAvatar'],
      comments: _parseStringList(map['comments']),
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
      userCompletionTimestamps:
          _parseTimestampMap(map['userCompletionTimestamps']),
      reportCompletionInfo: reportCompletionInfo,
      taskReviews: _parseStringMap(map['taskReviews']),
      taskRatings: _parseDoubleMap(map['taskRatings']),
      reviewTimestamps: _parseTimestampMap(map['reviewTimestamps']),
      reviewerRoles: _parseStringMap(map['reviewerRoles']),
    );
  }

  TaskMetadata copyWith({
    String? assignedReporter,
    String? assignedCameraman,
    String? assignedDriver,
    String? assignedLibrarian,
    String? assignedTo,
    DateTime? assignmentTimestamp,
    String? assignedReporterId,
    String? assignedCameramanId,
    String? assignedDriverId,
    String? assignedLibrarianId,
    String? creatorAvatar,
    List<String>? comments,
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
    Map<String, ReportCompletionInfo>? reportCompletionInfo,
    Map<String, String>? taskReviews,
    Map<String, double>? taskRatings,
    Map<String, DateTime>? reviewTimestamps,
    Map<String, String>? reviewerRoles,
  }) {
    return TaskMetadata(
      assignedReporter: assignedReporter ?? this.assignedReporter,
      assignedCameraman: assignedCameraman ?? this.assignedCameraman,
      assignedDriver: assignedDriver ?? this.assignedDriver,
      assignedLibrarian: assignedLibrarian ?? this.assignedLibrarian,
      assignedTo: assignedTo ?? this.assignedTo,
      assignmentTimestamp: assignmentTimestamp ?? this.assignmentTimestamp,
      assignedReporterId: assignedReporterId ?? this.assignedReporterId,
      assignedCameramanId: assignedCameramanId ?? this.assignedCameramanId,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedLibrarianId: assignedLibrarianId ?? this.assignedLibrarianId,
      creatorAvatar: creatorAvatar ?? this.creatorAvatar,
      comments: comments ?? this.comments,
      lastModified: lastModified ?? this.lastModified,
      syncStatus: syncStatus ?? this.syncStatus,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      approvedBy: approvedBy ?? this.approvedBy,
      approvalTimestamp: approvalTimestamp ?? this.approvalTimestamp,
      approvalReason: approvalReason ?? this.approvalReason,
      archivedAt: archivedAt ?? this.archivedAt,
      archivedBy: archivedBy ?? this.archivedBy,
      archiveReason: archiveReason ?? this.archiveReason,
      archiveLocation: archiveLocation ?? this.archiveLocation,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      attachmentNames: attachmentNames ?? this.attachmentNames,
      attachmentTypes: attachmentTypes ?? this.attachmentTypes,
      attachmentSizes: attachmentSizes ?? this.attachmentSizes,
      lastAttachmentAdded: lastAttachmentAdded ?? this.lastAttachmentAdded,
      completedByUserIds: completedByUserIds ?? this.completedByUserIds,
      userCompletionTimestamps:
          userCompletionTimestamps ?? this.userCompletionTimestamps,
      reportCompletionInfo: reportCompletionInfo ?? this.reportCompletionInfo,
      taskReviews: taskReviews ?? this.taskReviews,
      taskRatings: taskRatings ?? this.taskRatings,
      reviewTimestamps: reviewTimestamps ?? this.reviewTimestamps,
      reviewerRoles: reviewerRoles ?? this.reviewerRoles,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assignedReporter': assignedReporter,
      'assignedCameraman': assignedCameraman,
      'assignedDriver': assignedDriver,
      'assignedLibrarian': assignedLibrarian,
      'assignedTo': assignedTo,
      'assignmentTimestamp': assignmentTimestamp?.millisecondsSinceEpoch,
      'assignedReporterId': assignedReporterId,
      'assignedCameramanId': assignedCameramanId,
      'assignedDriverId': assignedDriverId,
      'assignedLibrarianId': assignedLibrarianId,
      'creatorAvatar': creatorAvatar,
      'comments': jsonEncode(comments),
      'lastModified': lastModified?.millisecondsSinceEpoch,
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
      'userCompletionTimestamps': jsonEncode(userCompletionTimestamps
          .map((key, value) => MapEntry(key, value.millisecondsSinceEpoch))),
      'reportCompletionInfo': jsonEncode(Map.fromEntries(reportCompletionInfo
          .entries
          .map((e) => MapEntry(e.key, e.value.toMap())))),
      'taskReviews': jsonEncode(taskReviews),
      'taskRatings':
          jsonEncode(taskRatings.map((k, v) => MapEntry(k, v.toString()))),
      'reviewTimestamps': jsonEncode(reviewTimestamps
          .map((k, v) => MapEntry(k, v.millisecondsSinceEpoch))),
      'reviewerRoles': jsonEncode(reviewerRoles),
    }..removeWhere((key, value) => value == null);
  }

  // Helper methods for parsing
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

  static Map<String, String> _parseStringMap(dynamic value) {
    if (value == null) return {};
    if (value is String) {
      try {
        return Map<String, String>.from(jsonDecode(value));
      } catch (e) {
        return {};
      }
    }
    if (value is Map) {
      return Map<String, String>.from(value);
    }
    return {};
  }

  static Map<String, double> _parseDoubleMap(dynamic value) {
    if (value == null) return {};
    if (value is String) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(value);
        return decoded
            .map((key, value) => MapEntry(key, double.parse(value.toString())));
      } catch (e) {
        return {};
      }
    }
    if (value is Map) {
      return Map<String, double>.from(value.map((key, value) =>
          MapEntry(key.toString(), double.parse(value.toString()))));
    }
    return {};
  }

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

  // Get average rating
  double get averageRating {
    if (taskRatings.isEmpty) return 0;
    final sum = taskRatings.values.reduce((a, b) => a + b);
    return sum / taskRatings.length;
  }

  @override
  String toString() {
    return 'TaskMetadata(attachments: ${attachmentUrls.length}, comments: ${comments.length}, reviews: ${taskReviews.length})';
  }
}
