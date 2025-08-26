// widgets/report_completion_dialog.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:task/models/report_completion_info.dart';
import 'package:task/utils/snackbar_utils.dart';

class ReportCompletionDialog extends StatefulWidget {
  final Function(ReportCompletionInfo) onComplete;

  const ReportCompletionDialog({
    super.key,
    required this.onComplete,
  });

  @override
  State<ReportCompletionDialog> createState() => _ReportCompletionDialogState();
}

class _ReportCompletionDialogState extends State<ReportCompletionDialog> {
  bool hasAired = false;
  DateTime? airTime;
  final TextEditingController videoEditorController = TextEditingController();
  final TextEditingController commentsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              'Report Completion Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Has the report aired?
            CheckboxListTile(
              title: const Text('Has this report aired?'),
              value: hasAired,
              onChanged: (value) {
                setState(() {
                  hasAired = value ?? false;
                  if (!hasAired) {
                    airTime = null;
                  }
                });
              },
            ),
            
            // Air time (only if hasAired is true)
            if (hasAired) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.access_time),
                label: Text(
                  airTime != null
                      ? 'Air Time: ${DateFormat('yyyy-MM-dd – HH:mm').format(airTime!)}'
                      : 'Select Air Time',
                ),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now(),
                  );
                  
                  if (date != null && context.mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    
                    if (time != null) {
                      setState(() {
                        airTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  }
                },
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Video editor name
            TextField(
              controller: videoEditorController,
              decoration: const InputDecoration(
                labelText: 'Video Editor Name',
                hintText: 'Who edited this report?',
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Additional comments
            TextField(
              controller: commentsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Additional Comments',
                hintText: 'Any additional notes about the report...',
              ),
            ),
            
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('CANCEL'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    try {
                      // Validate all required fields
                      if (hasAired && airTime == null) {
                        SnackbarUtils.showError(
                          'Please select the air time for the report',
                        );
                        return;
                      }
                      
                      if (videoEditorController.text.trim().isEmpty) {
                        SnackbarUtils.showError(
                          'Please enter the video editor\'s name',
                        );
                        return;
                      }
                      
                      // Create completion info object
                      final completionInfo = ReportCompletionInfo(
                        hasAired: hasAired,
                        airTime: airTime,
                        videoEditorName: videoEditorController.text.trim(),
                        comments: commentsController.text.trim().isNotEmpty
                            ? commentsController.text.trim()
                            : null,
                      );
                      
                      debugPrint('Created ReportCompletionInfo: ${completionInfo.toMap()}');
                      
                      // Call onComplete callback and close dialog
                      widget.onComplete(completionInfo);
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    } catch (e, stackTrace) {
                      debugPrint('Error in ReportCompletionDialog: $e');
                      debugPrint('Stack trace: $stackTrace');
                      SnackbarUtils.showError(
                        'Failed to submit completion info: ${e.toString()}',
                      );
                    }
                  },
                  child: const Text('SUBMIT'),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}
