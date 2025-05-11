import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String taskId;
  final String title;
  final String description;
  final String createdBy;
  final String? assignedReporter;
  final String? assignedCameraman;
  final String status;
  final List<String> comments; // ✅ Required field
  final Timestamp timestamp; // ✅ Required field

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
  });

  factory Task.fromMap(Map<String, dynamic> data) {
    return Task(
      taskId: data["taskId"] ?? "",
      title: data["title"] ?? "",
      description: data["description"] ?? "",
      createdBy: data["createdBy"] ?? "",
      assignedReporter: data["assignedReporter"],
      assignedCameraman: data["assignedCameraman"],
      status: data["status"] ?? "Pending",
      comments: List<String>.from(data["comments"] ?? []),
      timestamp: data["timestamp"] ?? Timestamp.now(),
    );
  }

  // ✅ Convert Task model to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'status': status,
      'comments': comments,
      'assignedReporter': assignedReporter,
      'assignedCameraman': assignedCameraman,
      'timestamp': timestamp,
    };
  }

  // ✅ Add copyWith method for immutability and updates
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
    );
  }
}