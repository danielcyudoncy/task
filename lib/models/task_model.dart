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
  final String? creatorAvatar; // Avatar URL from task document

  // --- New fields for category, tags, dueDate ---
  final String? category;
  final List<String>? tags;
  final DateTime? dueDate;

  Task({
    required this.taskId,
    required this.title,
    required this.description,
    required this.createdBy,
    this.assignedReporter,
    this.assignedCameraman,
    this.assignedTo,
    required this.status,
    required this.comments,
    required this.timestamp,
    required this.createdById,
    this.assignedReporterId,
    this.assignedCameramanId,
    this.assignmentTimestamp,
    this.creatorAvatar,
    this.category,
    this.tags,
    this.dueDate,
  });

  // Factory for Firestore maps
  factory Task.fromMap(Map<String, dynamic> map, String id) {
    print('fromMap: dueDate raw =  [33m${map['dueDate']} [0m type =  [33m${map['dueDate']?.runtimeType} [0m');
    print('fromMap: tags raw =  [33m${map['tags']} [0m type =  [33m${map['tags']?.runtimeType} [0m');
    print('fromMap: category raw =  [33m${map['category']} [0m type =  [33m${map['category']?.runtimeType} [0m');
    debugPrint('Task.fromMap: id=$id, category= [32m${map['category']} [0m, tags= [32m${map['tags']} [0m, dueDate= [32m${map['dueDate']} [0m');
    return Task(
      taskId: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['createdByName'] ?? '', // Should be filled in controller
      assignedReporter: map['assignedReporterName'], // Filled in controller
      assignedCameraman: map['assignedCameramanName'], // Filled in controller
      status: map['status'] ?? 'Pending',
      comments: map['comments'] != null && map['comments'] is List
          ? List<String>.from(map['comments'].whereType<String>())
          : <String>[],
      timestamp: map['timestamp'] is Timestamp
          ? map['timestamp']
          : (map['timestamp'] is String
              ? Timestamp.fromDate(DateTime.tryParse(map['timestamp']) ?? DateTime.now())
              : Timestamp.now()),
      createdById: map['createdBy'] ?? '',
      assignedTo: map['assignedTo'],
      assignedReporterId: map['assignedReporterId'],
      assignedCameramanId: map['assignedCameramanId'],
      assignmentTimestamp: map['assignmentTimestamp'] ?? map['assignedAt'],
      creatorAvatar: map['creatorAvatar'], // Get avatar directly from task document
      category: map['category']?.toString() ?? 'No category',
      tags: map['tags'] != null && map['tags'] is List
          ? List<String>.from(map['tags'].whereType<String>())
          : <String>[],
      dueDate: map['dueDate'] != null
          ? (map['dueDate'] is Timestamp
              ? (map['dueDate'] as Timestamp).toDate()
              : (map['dueDate'] is String
                  ? DateTime.tryParse(map['dueDate'])
                  : null))
          : null,
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
    String? status,
    List<String>? comments,
    Timestamp? timestamp,
    String? createdById,
    String? assignedReporterId,
    String? assignedCameramanId,
    Timestamp? assignmentTimestamp,
    String? creatorAvatar,
    String? category,
    List<String>? tags,
    DateTime? dueDate,
  }) {
    return Task(
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      assignedReporter: assignedReporter ?? this.assignedReporter,
      assignedCameraman: assignedCameraman ?? this.assignedCameraman,
      status: status ?? this.status,
      comments: comments ?? this.comments,
      timestamp: timestamp ?? this.timestamp,
      createdById: createdById ?? this.createdById,
      assignedReporterId: assignedReporterId ?? this.assignedReporterId,
      assignedCameramanId: assignedCameramanId ?? this.assignedCameramanId,
      assignmentTimestamp: assignmentTimestamp ?? this.assignmentTimestamp,
      creatorAvatar: creatorAvatar ?? this.creatorAvatar,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      dueDate: dueDate ?? this.dueDate,
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
      'status': status,
      'comments': comments,
      'timestamp': timestamp,
      'assignmentTimestamp': assignmentTimestamp,
      'category': category,
      'tags': tags,
      'dueDate': dueDate?.toIso8601String(),
    };
  }
}
