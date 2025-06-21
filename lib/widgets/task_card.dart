// widgets/task_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'status_chip.dart';

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isLargeScreen;
  final double textScale;
  final VoidCallback onTap;
  final ValueChanged<String> onAction;

  const TaskCard({
    required this.data,
    required this.isLargeScreen,
    required this.textScale,
    required this.onTap,
    required this.onAction,
    super.key,
  });
  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    final title = data['title'] ?? 'No title';
    final description = data['description'] ?? 'No description';
    final status = data['status'] ?? 'No status';
    final creatorName = data['creatorName'] ?? data['createdBy'];
    final creatorAvatar = data['creatorAvatar'];

    // Robust timestamp extraction & formatting
    final dynamic timestampRaw = data['timestamp'];
    String formattedTimestamp = '';
    if (timestampRaw != null) {
      if (timestampRaw is DateTime) {
        formattedTimestamp = timestampRaw.toLocal().toString();
      } else if (timestampRaw is String) {
        formattedTimestamp = timestampRaw;
      } else if (timestampRaw is int) {
        formattedTimestamp = DateTime.fromMillisecondsSinceEpoch(timestampRaw)
            .toLocal()
            .toString();
      } else if (timestampRaw.runtimeType.toString() == 'Timestamp') {
        formattedTimestamp =
            (timestampRaw as dynamic).toDate().toLocal().toString();
      }
    }

    final cardBg = colorScheme.surface;
    final cardShadow = isDark ? Colors.black45 : Colors.black12;
    final mainText =
        textTheme.bodyLarge?.color ?? (isDark ? Colors.white : Colors.black);
    final subText = isDark ? Colors.white70 : Colors.black54;
    final accent = colorScheme.primary;
    final avatarBg = isDark ? Colors.grey[800] : Colors.grey[200];

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: isLargeScreen ? 16 : 8.0, vertical: 4.0),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(12),
        shadowColor: cardShadow,
        color: cardBg,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Semantics(
            label: "Task card: $title, status $status, created by $creatorName",
            container: true,
            child: Container(
              padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
  children: [
    CircleAvatar(
      radius: isLargeScreen ? 25 : 18,
      backgroundColor: avatarBg,
      backgroundImage: creatorAvatar != null
          ? NetworkImage(creatorAvatar)
          : null,
      child: creatorAvatar == null
          ? Text(
              (creatorName.isNotEmpty ? creatorName[0] : "?")
                  .toUpperCase(),
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.bold,
                fontSize: isLargeScreen
                    ? 20.sp * textScale
                    : 15.sp * textScale,
              ),
            )
          : null,
    ),
    SizedBox(width: isLargeScreen ? 20 : 12),
    Expanded(
      child: Text(
        creatorName,
        style: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize:
              isLargeScreen ? 18.sp * textScale : 14.sp * textScale,
          color: mainText,
        ),
      ),
    ),
    StatusChip(status: status, textScale: textScale),
  ],
),
                  SizedBox(height: isLargeScreen ? 16 : 10),
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isLargeScreen ? 20 * textScale : 16.sp * textScale,
                      color: accent,
                    ),
                  ),
                  SizedBox(height: isLargeScreen ? 10 : 6),
                  Text(
                    description,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: isLargeScreen ? 16.sp * textScale : 13.sp * textScale,
                      color: mainText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (formattedTimestamp.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: subText),
                        const SizedBox(width: 6),
                        Text(
                          formattedTimestamp,
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 13.sp * textScale,
                            color: subText,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

