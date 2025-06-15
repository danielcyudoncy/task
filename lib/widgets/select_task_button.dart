// widgets/select_task_button.dart
import 'package:flutter/material.dart';

class SelectTaskButton extends StatelessWidget {
  final String? selectedTaskTitle;
  final List<String> taskTitles;
  final void Function(String?) onTaskSelected;

  const SelectTaskButton({
    Key? key,
    required this.selectedTaskTitle,
    required this.taskTitles,
    required this.onTaskSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () async {
        final picked = await showDialog<String>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text("Select Task"),
            children: taskTitles
                .map(
                  (t) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, t),
                    child: Text(t),
                  ),
                )
                .toList(),
          ),
        );
        if (picked != null) {
          onTaskSelected(picked);
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            selectedTaskTitle ?? "Select Task",
            style: TextStyle(
              color: selectedTaskTitle == null
                  ? Colors.grey
                  : Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}
