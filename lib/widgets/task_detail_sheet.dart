// widgets/task_detail_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'status_chip.dart';

class TaskDetailSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  final double textScale;
  final bool isDark;

  const TaskDetailSheet({
    required this.data,
    required this.textScale,
    required this.isDark,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    // Robust timestamp extraction & formatting
    final dynamic timestampRaw = data['timestamp'];
    String formattedTimestamp = '';
    if (timestampRaw != null) {
      if (timestampRaw is DateTime) {
        formattedTimestamp = timestampRaw.toLocal().toString();
      } else if (timestampRaw is String) {
        formattedTimestamp = timestampRaw;
      } else if (timestampRaw is int) {
        // If stored as millisecondsSinceEpoch
        formattedTimestamp = DateTime.fromMillisecondsSinceEpoch(timestampRaw)
            .toLocal()
            .toString();
      } else if (timestampRaw.runtimeType.toString() == 'Timestamp') {
        // For Firestore Timestamp type (as dynamic)
        formattedTimestamp =
            (timestampRaw as dynamic).toDate().toLocal().toString();
      }
    }

    // Theme-aware colors for better visibility
    final Color bgColor = colorScheme.surface;
    final Color mainText = colorScheme.onSurface;
    final Color subText = colorScheme.onSurfaceVariant;
    final Color avatarBg = isDark ? Colors.grey[700]! : Colors.grey[200]!;
    final Color accent = colorScheme.primary;
    final Color borderColor = colorScheme.outline;

    return Container(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: avatarBg,
                    backgroundImage: (data['creatorAvatar'] != null && data['creatorAvatar'].isNotEmpty && 
                        (data['creatorAvatar'].startsWith('http://') || data['creatorAvatar'].startsWith('https://')))
                        ? NetworkImage(data['creatorAvatar'])
                        : null,
                    child: (data['creatorAvatar'] == null || data['creatorAvatar'].isEmpty || 
                        !(data['creatorAvatar'].startsWith('http://') || data['creatorAvatar'].startsWith('https://')))
                        ? Text(
                            (data['creatorName'].isNotEmpty
                                    ? data['creatorName'][0]
                                    : "?")
                                .toUpperCase(),
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 18 * textScale,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  data['creatorName'] ?? '',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16 * textScale,
                    color: mainText,
                  ),
                ),
                const Spacer(),
                StatusChip(status: data['status'] ?? '', textScale: textScale),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              data['title'] ?? '',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20.sp * textScale,
                color: mainText,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data['description'] ?? '',
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 15.sp * textScale, 
                color: mainText
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: borderColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: subText),
                  const SizedBox(width: 6),
                  Text(
                    formattedTimestamp.isNotEmpty
                        ? formattedTimestamp
                        : 'No date',
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 13.sp * textScale, 
                      color: subText
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
