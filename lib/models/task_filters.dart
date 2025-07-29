// models/task_filters.dart

class TaskFilters {
  final List<String>? statuses;
  final List<String>? categories;
  final List<String>? tags;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? assignedToUserIds;

  TaskFilters({
    this.statuses,
    this.categories,
    this.tags,
    this.startDate,
    this.endDate,
    this.assignedToUserIds,
  });

  bool get hasActiveFilters {
    return (statuses?.isNotEmpty == true) ||
        (categories?.isNotEmpty == true) ||
        (tags?.isNotEmpty == true) ||
        startDate != null ||
        endDate != null ||
        (assignedToUserIds?.isNotEmpty == true);
  }

  TaskFilters copyWith({
    List<String>? statuses,
    List<String>? categories,
    List<String>? tags,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? assignedToUserIds,
  }) {
    return TaskFilters(
      statuses: statuses ?? this.statuses,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      assignedToUserIds: assignedToUserIds ?? this.assignedToUserIds,
    );
  }
}
