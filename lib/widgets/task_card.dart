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
    
    // Debug prints for avatar troubleshooting
    debugPrint("TaskCard: creatorName = $creatorName");
    debugPrint("TaskCard: creatorAvatar = $creatorAvatar");
    debugPrint("TaskCard: creatorAvatar type = ${creatorAvatar.runtimeType}");
    if (creatorAvatar != null) {
      debugPrint("TaskCard: creatorAvatar starts with http = ${creatorAvatar.toString().startsWith('http')}");
    }
    
    // Check CircleAvatar conditions
    final hasValidAvatar = creatorAvatar != null && creatorAvatar.isNotEmpty && 
        (creatorAvatar.startsWith('http://') || creatorAvatar.startsWith('https://'));
    debugPrint("TaskCard: hasValidAvatar = $hasValidAvatar");
    debugPrint("TaskCard: Will show backgroundImage = $hasValidAvatar");
    debugPrint("TaskCard: Will show child text = ${!hasValidAvatar}");

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

    // Theme-aware colors for better visibility
    final cardBg = colorScheme.surface;
    final cardShadow = isDark ? Colors.black45 : Colors.black12;
    final mainText = colorScheme.onSurface;
    final subText = colorScheme.onSurfaceVariant;
    final accent = colorScheme.primary;
    final avatarBg = isDark ? Colors.grey[700]! : Colors.grey[200]!;
    final borderColor = colorScheme.outline.withOpacity(0.3);

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
                border: Border.all(
                  color: borderColor,
                  width: 1,
                ),
              ),
              child: Column(
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
                          radius: isLargeScreen ? 25 : 18,
                          backgroundColor: avatarBg,
                          backgroundImage: (creatorAvatar != null && creatorAvatar.isNotEmpty && 
                              (creatorAvatar.startsWith('http://') || creatorAvatar.startsWith('https://')))
                              ? NetworkImage(creatorAvatar)
                              : null,
                          child: (creatorAvatar == null || creatorAvatar.isEmpty || 
                              !(creatorAvatar.startsWith('http://') || creatorAvatar.startsWith('https://')))
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
                      color: mainText,
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

