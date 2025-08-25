// models/report_completion_info.dart
class ReportCompletionInfo {
  final bool hasAired;
  final DateTime? airTime;
  final String? videoEditorName;
  final String? comments;

  ReportCompletionInfo({
    required this.hasAired,
    this.airTime,
    this.videoEditorName,
    this.comments,
  });

  Map<String, dynamic> toMap() {
    return {
      'hasAired': hasAired,
      'airTime': airTime?.toIso8601String(),
      'videoEditorName': videoEditorName,
      'comments': comments,
    };
  }

  factory ReportCompletionInfo.fromMap(Map<String, dynamic> map) {
    return ReportCompletionInfo(
      hasAired: map['hasAired'] ?? false,
      airTime: map['airTime'] != null ? DateTime.parse(map['airTime']) : null,
      videoEditorName: map['videoEditorName'],
      comments: map['comments'],
    );
  }
}
