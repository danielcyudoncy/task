import 'package:flutter/material.dart';
import 'status_chip.dart';

class TaskDetailSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  final double textScale;
  const TaskDetailSheet({required this.data, required this.textScale, super.key});

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
        formattedTimestamp = DateTime.fromMillisecondsSinceEpoch(timestampRaw).toLocal().toString();
      } else if (timestampRaw.runtimeType.toString() == 'Timestamp') {
        // For Firestore Timestamp type (as dynamic)
        formattedTimestamp = (timestampRaw as dynamic).toDate().toLocal().toString();
      }
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[200],
                backgroundImage: data['creatorAvatar'] != null ? NetworkImage(data['creatorAvatar']) : null,
                child: data['creatorAvatar'] == null
                    ? Text(
                        (data['creatorName'].isNotEmpty ? data['creatorName'][0] : "?").toUpperCase(),
                        style: TextStyle(
                          color: const Color(0xFF171FA0),
                          fontWeight: FontWeight.bold,
                          fontSize: 18 * textScale,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                data['creatorName'] ?? '',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16 * textScale,
                  color: const Color(0xFF171FA0),
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
              fontSize: 20 * textScale,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data['description'] ?? '',
            style: TextStyle(fontSize: 15 * textScale),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
              const SizedBox(width: 6),
              Text(
                formattedTimestamp.isNotEmpty ? formattedTimestamp : 'No date',
                style: TextStyle(fontSize: 13 * textScale, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}