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
  Id isarId = Isar.autoIncrement; // Local Isar ID

  late String taskId;
  late String title;
  late String description;
  late String createdBy; // Human-readable name
  String? assignedReporter; // Human-readable name (nullable)
  String? assignedCameraman; // Human-readable name (nullable)
  String? assignedDriver; // Human-readable name (nullable)
  String? assignedLibrarian; // Human-readable name (nullable)
  late String status;
  List<String> comments = [];
  late DateTime timestamp;
  String? assignedTo;

  /// Timestamp for when the task was assigned to a user (for daily tracking)
  DateTime? assignmentTimestamp;

  // New fields for robust filtering & permission checks
  late String createdById;
  String? assignedReporterId;
  String? assignedCameramanId;
  String? assignedDriverId;
  String? assignedLibrarianId;
  String? creatorAvatar; // Avatar URL from task document

  // --- New fields for category, tags, dueDate ---
  String? category;
  List<String> tags = [];
  DateTime? dueDate;
  String? priority;

  DateTime? lastModified;
  String? syncStatus; // 'pending', 'synced', 'conflict'

  Task()
      : taskId = '',
        title = '',
        description = '',
        createdBy = '',
        assignedReporter = null,
        assignedCameraman = null,
        assignedDriver = null,
        assignedLibrarian = null,
        status = '',
        comments = const [],
        timestamp = DateTime.now(),
        assignedTo = null,
        assignmentTimestamp = null,
        createdById = '',
        assignedReporterId = null,
        assignedCameramanId = null,
        assignedDriverId = null,
        assignedLibrarianId = null,
        creatorAvatar = null,
        category = null,
        tags = const [],
        dueDate = null,
        priority = null,
        lastModified = DateTime.now(),
        syncStatus = 'pending';
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
    {this.lastModified, this.syncStatus}
  );

  // Factory for Firestore maps
  factory Task.fromMap(Map<String, dynamic> map, String id) {
    debugPrint('fromMap: id=$id, category=${map['category']}, tags=${map['tags']}, dueDate=${map['dueDate']}, priority=${map['priority']}');
    debugPrint('fromMap: assignedReporterId=${map['assignedReporterId']}, assignedCameramanId=${map['assignedCameramanId']}, assignedDriverId=${map['assignedDriverId']}, assignedLibrarianId=${map['assignedLibrarianId']}');
    return Task.full(
      map['taskId'] ?? id,
      map['title'] ?? '',
      map['description'] ?? '',
      map['createdBy'] ?? '',
      map['assignedReporter'],
      map['assignedCameraman'],
      map['assignedDriver'],
      map['assignedLibrarian'],
      map['status'] ?? '',
      List<String>.from(map['comments'] ?? []),
      // timestamp
      parseDate(map['timestamp']) ?? DateTime.now(),
      map['assignedTo'],
      // assignmentTimestamp
      parseDate(map['assignmentTimestamp']),
      map['createdById'] ?? '',
      map['assignedReporterId'],
      map['assignedCameramanId'],
      map['assignedDriverId'],
      map['assignedLibrarianId'],
      map['creatorAvatar'],
      map['category'],
      List<String>.from(map['tags'] ?? []),
      // dueDate
      parseDate(map['dueDate']),
      map['priority'],
      lastModified: parseDate(map['lastModified']),
      syncStatus: map['syncStatus'],
    );
  }

  // copyWith for safe updates
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
    String? createdById,
    String? assignedReporterId,
    String? assignedCameramanId,
    String? assignedDriverId,
    String? assignedLibrarianId,
    DateTime? assignmentTimestamp,
    String? creatorAvatar,
    String? category,
    List<String>? tags,
    DateTime? dueDate,
    String? priority,
    String? assignedTo,
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
      comments ?? this.comments,
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
      tags ?? this.tags,
      dueDate ?? this.dueDate,
      priority ?? this.priority,
    );
  }

  /// Converts the Task to a Map for UI widgets, injecting human-readable names from cache if needed.
  Map<String, dynamic> toMapWithUserInfo(Map<String, String> userNameCache, [Map<String, String>? userAvatarCache]) {
    // Use creatorAvatar from task document first, fallback to cache
    final avatarFromTask = creatorAvatar ?? '';
    final avatarFromCache = userAvatarCache?[createdById] ?? '';
    final finalCreatorAvatar = avatarFromTask.isNotEmpty ? avatarFromTask : avatarFromCache;
    
    debugPrint("TaskModel: createdById = $createdById");
    debugPrint("TaskModel: creatorAvatar from task = $avatarFromTask");
    debugPrint("TaskModel: creatorAvatar from cache = $avatarFromCache");
    debugPrint("TaskModel: final creatorAvatar = $finalCreatorAvatar");
    
    return {
      'taskId': taskId,
      'title': title,
      'description': description,
      'createdBy': createdById, // original user id
      'creatorName': userNameCache[createdById] ?? createdBy,
      'creatorAvatar': finalCreatorAvatar,
      'assignedReporter': assignedReporterId,
      'assignedReporterName': assignedReporterId != null
          ? (userNameCache[assignedReporterId!] ??
              assignedReporter ??
              'Not Assigned')
          : 'Not Assigned',
      'assignedCameraman': assignedCameramanId,
      'assignedCameramanName': assignedCameramanId != null
          ? (userNameCache[assignedCameramanId!] ??
              assignedCameraman ??
              'Not Assigned')
          : 'Not Assigned',
      'assignedDriver': assignedDriverId,
      'assignedDriverName': assignedDriverId != null
          ? (userNameCache[assignedDriverId!] ??
              assignedDriver ??
              'Not Assigned')
          : 'Not Assigned',
      'assignedLibrarian': assignedLibrarianId,
      'assignedLibrarianName': assignedLibrarianId != null
          ? (userNameCache[assignedLibrarianId!] ??
              assignedLibrarian ??
              'Not Assigned')
          : 'Not Assigned',
      'status': status,
      'comments': comments,
      'timestamp': timestamp,
      'assignmentTimestamp': assignmentTimestamp?.toIso8601String(),
      'category': category,
      'tags': tags,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority,
    };
  }
}
