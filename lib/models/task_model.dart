// models/task_model.dart
class Task {
  String taskId;
  String title;
  String description;
  String createdBy;
  String? assignedReporter;
  String? assignedCameraman;
  String status;
  List<Map<String, dynamic>> comments;

  Task({
    required this.taskId,
    required this.title,
    required this.description,
    required this.createdBy,
    this.assignedReporter,
    this.assignedCameraman,
    this.status = "Pending",
    this.comments = const [],
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      taskId: map['taskId'],
      title: map['title'],
      description: map['description'],
      createdBy: map['createdBy'],
      assignedReporter: map['assignedReporter'],
      assignedCameraman: map['assignedCameraman'],
      status: map['status'],
      comments: List<Map<String, dynamic>>.from(map['comments'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "taskId": taskId,
      "title": title,
      "description": description,
      "createdBy": createdBy,
      "assignedReporter": assignedReporter,
      "assignedCameraman": assignedCameraman,
      "status": status,
      "comments": comments,
    };
  }
}
