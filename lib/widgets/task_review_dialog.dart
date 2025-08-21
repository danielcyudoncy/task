// widgets/task_review_dialog.dart
import 'package:flutter/material.dart';
import '../models/task_model.dart';

class TaskReviewDialog extends StatefulWidget {
  final Task task;
  final String reviewerId;
  final String reviewerRole;
  final Function onReviewSubmitted;

  const TaskReviewDialog({
    super.key,
    required this.task,
    required this.reviewerId,
    required this.reviewerRole,
    required this.onReviewSubmitted,
  });

  @override
  State<TaskReviewDialog> createState() => _TaskReviewDialogState();
}

class _TaskReviewDialogState extends State<TaskReviewDialog> {
  final _commentController = TextEditingController();
  double _rating = 3.0;
  String? _error;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitReview() {
    try {
      if (_commentController.text.trim().isEmpty) {
        setState(() => _error = 'Please provide a review comment');
        return;
      }

      widget.task.addReview(
        widget.reviewerId,
        widget.reviewerRole,
        _commentController.text.trim(),
        _rating,
      );

      widget.onReviewSubmitted();
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Review Task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rating'),
            Slider(
              value: _rating,
              min: 1,
              max: 5,
              divisions: 4,
              label: _rating.toString(),
              onChanged: (value) => setState(() => _rating = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Review Comment',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitReview,
          child: const Text('Submit Review'),
        ),
      ],
    );
  }
}
