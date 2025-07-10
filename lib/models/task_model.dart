// models/task_model.dart
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
  });

  // Factory for Firestore maps
  factory Task.fromMap(Map<String, dynamic> map, String id) {
    return Task(
      taskId: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['createdByName'] ?? '', // Should be filled in controller
      assignedReporter: map['assignedReporterName'], // Filled in controller
      assignedCameraman: map['assignedCameramanName'], // Filled in controller
      status: map['status'] ?? 'Pending',
      comments: List<String>.from(map['comments'] ?? []),
      timestamp: map['timestamp'] ?? Timestamp.now(),
      createdById: map['createdBy'] ?? '',
      assignedTo: map['assignedTo'],
      assignedReporterId: map['assignedReporter'],
      assignedCameramanId: map['assignedCameraman'],
      assignmentTimestamp: map['assignmentTimestamp'] ?? map['assignedAt'],
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
    );
  }

  /// Converts the Task to a Map for UI widgets, injecting human-readable names from cache if needed.
  Map<String, dynamic> toMapWithUserInfo(Map<String, String> userNameCache, [Map<String, String>? userAvatarCache]) {
    return {
      'taskId': taskId,
      'title': title,
      'description': description,
      'createdBy': createdById, // original user id
      'creatorName': userNameCache[createdById] ?? createdBy,
      'creatorAvatar': userAvatarCache?[createdById] ?? '',
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
    };
  }
}
