class TaskFilters {
  List<String>? statuses;
  List<String>? categories;
  List<String>? tags;
  DateTime? startDate;
  DateTime? endDate;
  List<String>? assignedToUserIds;

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

  Map<String, dynamic> toMap() {
    return {
      'statuses': statuses,
      'categories': categories,
      'tags': tags,
      'startDate': startDate?.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'assignedToUserIds': assignedToUserIds,
    }..removeWhere((key, value) => value == null);
  }

  factory TaskFilters.fromMap(Map<String, dynamic> map) {
    return TaskFilters(
      statuses: map['statuses'] != null ? List<String>.from(map['statuses']) : null,
      categories: map['categories'] != null ? List<String>.from(map['categories']) : null,
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
      startDate: map['startDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['startDate']) : null,
      endDate: map['endDate'] != null ? DateTime.fromMillisecondsSinceEpoch(map['endDate']) : null,
      assignedToUserIds: map['assignedToUserIds'] != null ? List<String>.from(map['assignedToUserIds']) : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskFilters &&
        _listsEqual(other.statuses, statuses) &&
        _listsEqual(other.categories, categories) &&
        _listsEqual(other.tags, tags) &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        _listsEqual(other.assignedToUserIds, assignedToUserIds);
  }

  @override
  int get hashCode {
    return Object.hash(
      statuses?.length,
      categories?.length,
      tags?.length,
      startDate,
      endDate,
      assignedToUserIds?.length,
    );
  }

  bool _listsEqual<T>(List<T>? a, List<T>? b) {
    if (a == b) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
