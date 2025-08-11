// models/task_model.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

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
  
  // Media & Document Attachments
  List<String> attachmentUrls = []; // URLs of uploaded files
  List<String> attachmentNames = []; // Original file names
  List<String> attachmentTypes = []; // File types (image, document, video, etc.)
  List<int> attachmentSizes = []; // File sizes in bytes
  DateTime? lastAttachmentAdded;
  
  // Archive related fields
  bool get isArchived => status.toLowerCase() == 'archived';
  
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
  String? archiveLocation; // Physical or digital location where the task is archived
  
  // Individual user completion tracking
  List<String> completedByUserIds = []; // List of user IDs who have marked this task as complete
  Map<String, DateTime> userCompletionTimestamps = {}; // Track when each user completed the task

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
        attachmentUrls = [],
        attachmentNames = [],
        attachmentTypes = [],
        attachmentSizes = [],
        completedByUserIds = [],
        userCompletionTimestamps = {};

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
      this.comments,
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
      this.tags,
      this.dueDate,
      this.priority,
      {this.lastModified,
      this.syncStatus,
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
      this.userCompletionTimestamps = const {}});

  factory Task.fromMap(Map<String, dynamic> map) {
    String taskId = map['taskId'] ?? map['id']?.toString() ?? '';
    debugPrint(
        'fromMap creator data: createdBy=${map['createdBy']}, createdByName=${map['createdByName']}');

    return Task.full(
      taskId,
      map['title'] ?? '',
      map['description'] ?? '',
      map['createdByName'] ??
          map['createdBy'] ??
          'Unknown', // Prefer createdByName
      map['assignedReporterName'] ?? map['assignedReporter'],
      map['assignedCameramanName'] ?? map['assignedCameraman'],
      map['assignedDriverName'] ?? map['assignedDriver'],
      map['assignedLibrarian'],
      map['status'] ?? '',
      _parseStringList(map['comments']),
      parseDate(map['timestamp']) ?? DateTime.now(),
      map['assignedTo'],
      parseDate(map['assignmentTimestamp']),
      map['createdBy'] ?? '', // This should be the user ID
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
      userCompletionTimestamps: _parseTimestampMap(map['userCompletionTimestamps']),
    );
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
      archivedAt: archivedAt ?? this.archivedAt,
      archivedBy: archivedBy ?? this.archivedBy,
      archiveReason: archiveReason ?? this.archiveReason,
      archiveLocation: archiveLocation ?? this.archiveLocation,
      attachmentUrls: attachmentUrls ?? List.from(this.attachmentUrls),
      attachmentNames: attachmentNames ?? List.from(this.attachmentNames),
      attachmentTypes: attachmentTypes ?? List.from(this.attachmentTypes),
      attachmentSizes: attachmentSizes ?? List.from(this.attachmentSizes),
      lastAttachmentAdded: lastAttachmentAdded ?? this.lastAttachmentAdded,
      completedByUserIds: completedByUserIds ?? List.from(this.completedByUserIds),
      userCompletionTimestamps: userCompletionTimestamps ?? Map.from(this.userCompletionTimestamps),
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
      'userCompletionTimestamps': jsonEncode(userCompletionTimestamps.map((key, value) => MapEntry(key, value.millisecondsSinceEpoch))),
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
        return decoded.map((key, value) => MapEntry(key, DateTime.fromMillisecondsSinceEpoch(value as int)));
      } catch (e) {
        return {};
      }
    }
    if (value is Map) {
      return Map<String, DateTime>.from(
        value.map((key, value) => MapEntry(key.toString(), parseDate(value) ?? DateTime.now()))
      );
    }
    return {};
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
