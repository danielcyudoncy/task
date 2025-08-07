// models/task_model.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isar/isar.dart';
part 'task_model.g.dart';

DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

@Collection()
class Task {
  Id isarId = Isar.autoIncrement;

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
  DateTime? archivedAt;
  String? archivedBy;
  String? archiveReason;
  String? archiveLocation; // Physical or digital location where the task is archived

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
        attachmentSizes = [];

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
      this.lastAttachmentAdded});

  factory Task.fromMap(Map<String, dynamic> map, String id) {
    debugPrint(
        'fromMap creator data: createdBy=${map['createdBy']}, createdByName=${map['createdByName']}');

    return Task.full(
      map['taskId'] ?? id,
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
      List<String>.from(map['comments'] ?? []),
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
      List<String>.from(map['tags'] ?? []),
      parseDate(map['dueDate']),
      map['priority'],
      lastModified: parseDate(map['lastModified']),
      syncStatus: map['syncStatus'],
      archivedAt: parseDate(map['archivedAt']),
      archivedBy: map['archivedBy'],
      archiveReason: map['archiveReason'],
      archiveLocation: map['archiveLocation'],
      attachmentUrls: List<String>.from(map['attachmentUrls'] ?? []),
      attachmentNames: List<String>.from(map['attachmentNames'] ?? []),
      attachmentTypes: List<String>.from(map['attachmentTypes'] ?? []),
      attachmentSizes: List<int>.from(map['attachmentSizes'] ?? []),
      lastAttachmentAdded: parseDate(map['lastAttachmentAdded']),
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'assignedReporter': assignedReporter,
      'assignedCameraman': assignedCameraman,
      'assignedDriver': assignedDriver,
      'assignedLibrarian': assignedLibrarian,
      'status': status,
      'comments': comments,
      'timestamp': timestamp,
      'assignedTo': assignedTo,
      'assignmentTimestamp': assignmentTimestamp,
      'createdById': createdById,
      'assignedReporterId': assignedReporterId,
      'assignedCameramanId': assignedCameramanId,
      'assignedDriverId': assignedDriverId,
      'assignedLibrarianId': assignedLibrarianId,
      'creatorAvatar': creatorAvatar,
      'category': category,
      'tags': tags,
      'dueDate': dueDate,
      'priority': priority,
      'lastModified': lastModified ?? DateTime.now(),
      'syncStatus': syncStatus,
      'archivedAt': archivedAt,
      'archivedBy': archivedBy,
      'archiveReason': archiveReason,
      'archiveLocation': archiveLocation,
      'attachmentUrls': attachmentUrls,
      'attachmentNames': attachmentNames,
      'attachmentTypes': attachmentTypes,
      'attachmentSizes': attachmentSizes,
      'lastAttachmentAdded': lastAttachmentAdded,
    }..removeWhere((key, value) => value == null);
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
