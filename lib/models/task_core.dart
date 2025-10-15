// models/task_core.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Core task data - essential fields that are always loaded
class TaskCore {
  final String taskId;
  final String title;
  final String description;
  final String createdBy;
  final String createdById;
  final String? createdByName;
  final String status;
  final DateTime timestamp;
  final String? priority;
  final DateTime? dueDate;
  final String? category;
  final List<String> tags;

  // Computed properties
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isInProgress => status.toLowerCase() == 'in progress';
  bool get isOverdue =>
      dueDate != null && dueDate!.isBefore(DateTime.now()) && !isCompleted;

  TaskCore({
    required this.taskId,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.createdById,
    this.createdByName,
    required this.status,
    required this.timestamp,
    this.priority,
    this.dueDate,
    this.category,
    this.tags = const [],
  });

  factory TaskCore.fromMap(Map<String, dynamic> map) {
    return TaskCore(
      taskId: map['taskId'] ?? map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdBy: map['createdBy'] ?? 'Unknown',
      createdById: map['createdById'] ?? map['createdBy'] ?? '',
      createdByName: map['createdByName'],
      status: map['status'] ?? 'Pending',
      timestamp: parseDate(map['timestamp']) ?? DateTime.now(),
      priority: map['priority'],
      dueDate: parseDate(map['dueDate']),
      category: map['category'],
      tags: _parseStringList(map['tags']),
    );
  }

  TaskCore copyWith({
    String? taskId,
    String? title,
    String? description,
    String? createdBy,
    String? createdById,
    String? createdByName,
    String? status,
    DateTime? timestamp,
    String? priority,
    DateTime? dueDate,
    String? category,
    List<String>? tags,
  }) {
    return TaskCore(
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'createdById': createdById,
      'createdByName': createdByName,
      'status': status,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'priority': priority,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'category': category,
      'tags': tags,
    }..removeWhere((key, value) => value == null);
  }

  // Helper method for parsing string lists
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

  @override
  String toString() {
    return 'TaskCore(taskId: $taskId, title: $title, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskCore && other.taskId == taskId;
  }

  @override
  int get hashCode => taskId.hashCode;
}
