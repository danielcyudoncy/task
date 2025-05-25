import 'package:flutter/material.dart';
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
    final title = data['title'] ?? 'No title';
    final description = data['description'] ?? 'No description';
    final status = data['status'] ?? 'No status';
    final creatorName = data['creatorName'] ?? data['createdBy'];
    final creatorAvatar = data['creatorAvatar'] ?? null;

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
        formattedTimestamp = DateTime.fromMillisecondsSinceEpoch(timestampRaw).toLocal().toString();
      } else if (timestampRaw.runtimeType.toString() == 'Timestamp') {
        // For Firestore Timestamp type (as dynamic)
        formattedTimestamp = (timestampRaw as dynamic).toDate().toLocal().toString();
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 16 : 8.0, vertical: 4.0),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(12),
        shadowColor: const Color(0x1A000000),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Semantics(
            label: "Task card: $title, status $status, created by $creatorName",
            container: true,
            child: Container(
              padding: EdgeInsets.all(isLargeScreen ? 24 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: isLargeScreen ? 25 : 18,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: creatorAvatar != null ? NetworkImage(creatorAvatar) : null,
                        child: creatorAvatar == null
                            ? Text(
                                (creatorName.isNotEmpty ? creatorName[0] : "?").toUpperCase(),
                                style: TextStyle(
                                  color: const Color(0xFF171FA0),
                                  fontWeight: FontWeight.bold,
                                  fontSize: isLargeScreen ? 20 * textScale : 15 * textScale,
                                ),
                              )
                            : null,
                      ),
                      SizedBox(width: isLargeScreen ? 20 : 12),
                      Expanded(
                        child: Text(
                          creatorName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isLargeScreen ? 18 * textScale : 14 * textScale,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      StatusChip(status: status, textScale: textScale),
                      _TaskActionMenu(
                        taskData: data,
                        onAction: onAction,
                      ),
                    ],
                  ),
                  SizedBox(height: isLargeScreen ? 16 : 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isLargeScreen ? 20 * textScale : 16 * textScale,
                      color: const Color(0xFF171FA0),
                    ),
                  ),
                  SizedBox(height: isLargeScreen ? 10 : 6),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: isLargeScreen ? 16 * textScale : 13 * textScale,
                      color: Colors.black87,
                    ),
                  ),
                  // Timestamp (optional, style as you wish)
                  SizedBox(height: 8),
                  if (formattedTimestamp.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
                        const SizedBox(width: 6),
                        Text(
                          formattedTimestamp,
                          style: TextStyle(fontSize: 13 * textScale, color: Colors.black54),
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

class _TaskActionMenu extends StatelessWidget {
  final Map<String, dynamic> taskData;
  final ValueChanged<String> onAction;
  const _TaskActionMenu({required this.taskData, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Color(0xFF171FA0)),
      onSelected: onAction,
      itemBuilder: (context) {
        List<PopupMenuEntry<String>> items = [
          const PopupMenuItem<String>(
            value: 'Edit',
            child: Text('Edit'),
          ),
          const PopupMenuItem<String>(
            value: 'Delete',
            child: Text('Delete'),
          ),
        ];
        if (taskData['status'] != "Completed") {
          items.insert(
              0,
              const PopupMenuItem<String>(
                value: 'Mark as Completed',
                child: Text('Mark as Completed'),
              ));
        }
        return items;
      },
    );
  }
}