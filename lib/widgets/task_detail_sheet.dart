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

    final Color bgColor = isDark ? Colors.grey[900]! : Colors.white;
    final Color mainText = isDark ? Colors.white : Colors.black;
    final Color subText = isDark ? Colors.white70 : Colors.black54;
    final Color avatarBg = isDark ? Colors.grey[850]! : Colors.grey[200]!;
    const Color accent = Color(0xFF08169D);

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
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.onPrimary
                          : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: avatarBg,
                    backgroundImage: data['creatorAvatar'] != null
                        ? NetworkImage(data['creatorAvatar'])
                        : null,
                    child: data['creatorAvatar'] == null
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'raleway',
                    fontSize: 16 * textScale,
                    color: accent,
                  ),
                ),
                const Spacer(),
                StatusChip(status: data['status'] ?? '', textScale: textScale),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              data['title'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20.sp * textScale,
                color: mainText,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data['description'] ?? '',
              style: TextStyle(fontSize: 15.sp * textScale, color: mainText),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: subText),
                const SizedBox(width: 6),
                Text(
                  formattedTimestamp.isNotEmpty
                      ? formattedTimestamp
                      : 'No date',
                  style: TextStyle(fontSize: 13.sp * textScale, color: subText),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
