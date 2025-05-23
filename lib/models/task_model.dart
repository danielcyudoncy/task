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
    required this.status,
    required this.comments,
    required this.timestamp,
    required this.createdById,
    this.assignedReporterId,
    this.assignedCameramanId,
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
      assignedReporterId: map['assignedReporter'],
      assignedCameramanId: map['assignedCameraman'],
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
    );
  }
}
