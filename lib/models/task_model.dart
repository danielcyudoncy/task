// models/task_model.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String taskId;
  final String title;
  final String description;
  final String createdBy; // Human-readable name
  final String? assignedReporter; // Human-readable name (nullable)
  final String? assignedCameraman; // Human-readable name (nullable)
  final String? assignedDriver; // Human-readable name (nullable)
  final String? assignedLibrarian; // Human-readable name (nullable)
  final String status;
  final List<String> comments;
  final Timestamp timestamp;
  final String? assignedTo;

  /// Timestamp for when the task was assigned to a user (for daily tracking)
  final Timestamp? assignmentTimestamp;

  // New fields for robust filtering & permission checks
  final String createdById;
  final String? assignedReporterId;
  final String? assignedCameramanId;
  final String? assignedDriverId;
  final String? assignedLibrarianId;
  final String? creatorAvatar; // Avatar URL from task document

  // --- New fields for category, tags, dueDate ---
  final String? category;
  final List<String>? tags;
  final DateTime? dueDate;
  final String? priority;

  Task({
    required this.taskId,
    required this.title,
    required this.description,
    required this.createdBy,
    this.assignedReporter,
    this.assignedCameraman,
    this.assignedDriver,
    this.assignedLibrarian,
    this.assignedTo,
    required this.status,
    required this.comments,
    required this.timestamp,
    required this.createdById,
    this.assignedReporterId,
    this.assignedCameramanId,
    this.assignedDriverId,
    this.assignedLibrarianId,
    this.assignmentTimestamp,
    this.creatorAvatar,
    this.category,
    this.tags,
    this.dueDate,
    this.priority,
  });

  // Factory for Firestore maps
  factory Task.fromMap(Map<String, dynamic> map, String id) {
    debugPrint('fromMap: id=$id, category=${map['category']}, tags=${map['tags']}, dueDate=${map['dueDate']}, priority=${map['priority']}');
    debugPrint('fromMap: assignedReporterId=${map['assignedReporterId']}, assignedCameramanId=${map['assignedCameramanId']}, assignedDriverId=${map['assignedDriverId']}, assignedLibrarianId=${map['assignedLibrarianId']}');
    return Task(
      taskId: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['createdByName'] ?? '',
      assignedReporter: map['assignedReporterName'],
      assignedCameraman: map['assignedCameramanName'],
      assignedDriver: map['assignedDriverName'],
      assignedLibrarian: map['assignedLibrarianName'],
      status: map['status'] ?? 'Pending',
      comments: List<String>.from(map['comments'] ?? []),
      timestamp: map['timestamp'] is Timestamp
          ? map['timestamp']
          : (map['timestamp'] != null ? Timestamp.fromDate(DateTime.parse(map['timestamp'])) : Timestamp.now()),
      createdById: map['createdBy'] ?? '',
      assignedTo: map['assignedTo'],
      assignedReporterId: map['assignedReporterId'],  // ✅ Fixed field name
      assignedCameramanId: map['assignedCameramanId'], // ✅ Fixed field name
      assignedDriverId: map['assignedDriverId'],
      assignedLibrarianId: map['assignedLibrarianId'],
      assignmentTimestamp: map['assignmentTimestamp'],
      creatorAvatar: map['creatorAvatar'],
      category: map['category'] ?? '',
      tags: map['tags'] is List ? List<String>.from(map['tags']) : [],
      dueDate: map['dueDate'] != null && map['dueDate'] != ''
          ? (map['dueDate'] is String
              ? DateTime.tryParse(map['dueDate'])
              : (map['dueDate'] is Timestamp
                  ? (map['dueDate'] as Timestamp).toDate()
                  : null))
          : null,
      priority: map['priority'] ?? 'Normal',
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
    Timestamp? timestamp,
    String? createdById,
    String? assignedReporterId,
    String? assignedCameramanId,
    String? assignedDriverId,
    String? assignedLibrarianId,
    Timestamp? assignmentTimestamp,
    String? creatorAvatar,
    String? category,
    List<String>? tags,
    DateTime? dueDate,
    String? priority,
  }) {
    return Task(
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      assignedReporter: assignedReporter ?? this.assignedReporter,
      assignedCameraman: assignedCameraman ?? this.assignedCameraman,
      assignedDriver: assignedDriver ?? this.assignedDriver,
      assignedLibrarian: assignedLibrarian ?? this.assignedLibrarian,
      status: status ?? this.status,
      comments: comments ?? this.comments,
      timestamp: timestamp ?? this.timestamp,
      createdById: createdById ?? this.createdById,
      assignedReporterId: assignedReporterId ?? this.assignedReporterId,
      assignedCameramanId: assignedCameramanId ?? this.assignedCameramanId,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedLibrarianId: assignedLibrarianId ?? this.assignedLibrarianId,
      assignmentTimestamp: assignmentTimestamp ?? this.assignmentTimestamp,
      creatorAvatar: creatorAvatar ?? this.creatorAvatar,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
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
      'assignmentTimestamp': assignmentTimestamp,
      'category': category,
      'tags': tags,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority,
    };
  }
}
