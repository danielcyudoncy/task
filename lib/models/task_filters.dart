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
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return TaskFilters(
      statuses: statuses ?? this.statuses?.toList(),
      categories: categories ?? this.categories?.toList(),
      tags: tags ?? this.tags?.toList(),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      assignedToUserIds: assignedToUserIds ?? this.assignedToUserIds?.toList(),
    );
  }
}
