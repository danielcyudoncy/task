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

  Task()
      : taskId = '',
        title = '',
        description = '',
        createdBy = '',
        status = '',
        timestamp = DateTime.now(),
        createdById = '',
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
      {this.lastModified,
      this.syncStatus});

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
      map['assignedReporter'],
      map['assignedCameraman'],
      map['assignedDriver'],
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
    );
  }

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
