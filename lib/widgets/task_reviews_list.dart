// widgets/task_reviews_list.dart
import 'package:flutter/material.dart';
import '../models/task_model.dart';

class TaskReviewsList extends StatelessWidget {
  final Task task;
  final Map<String, String> userNames; // Map of user IDs to display names
  final bool canManageReviews; // Whether the current user can delete reviews

  const TaskReviewsList({
    super.key,
    required this.task,
    required this.userNames,
    this.canManageReviews = false,
  });

  @override
  Widget build(BuildContext context) {
    if (task.taskReviews.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No reviews yet'),
        ),
      );
    }

    // Sort reviews by timestamp, most recent first
    final sortedReviewers = task.taskReviews.keys.toList()
      ..sort((a, b) => (task.reviewTimestamps[b]?.compareTo(
              task.reviewTimestamps[a] ?? DateTime.now()) ??
          0));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedReviewers.length,
      itemBuilder: (context, index) {
        final reviewerId = sortedReviewers[index];
        final review = task.taskReviews[reviewerId];
        final rating = task.taskRatings[reviewerId];
        final timestamp = task.reviewTimestamps[reviewerId];
        final role = task.reviewerRoles[reviewerId];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userNames[reviewerId] ?? 'Unknown User',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            role?.replaceAll('_', ' ').toUpperCase() ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating?.toStringAsFixed(1) ?? 'N/A',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (canManageReviews) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Review'),
                                  content: const Text(
                                      'Are you sure you want to delete this review?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        task.removeReview(reviewerId);
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Delete'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .error,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(review ?? ''),
                const SizedBox(height: 4),
                if (timestamp != null)
                  Text(
                    'Reviewed on ${timestamp.toLocal().toString().split('.')[0]}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
