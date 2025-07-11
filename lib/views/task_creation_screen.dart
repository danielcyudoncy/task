// views/task_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/task_controller.dart';
import 'package:task/utils/constants/app_styles.dart';
import 'package:task/utils/constants/app_sizes.dart';
import 'package:task/utils/devices/app_devices.dart';

class TaskCreationScreen extends StatefulWidget {
  const TaskCreationScreen({super.key});

  @override
  State<TaskCreationScreen> createState() => _TaskCreationScreenState();
}

class _TaskCreationScreenState extends State<TaskCreationScreen> {
  final TaskController taskController = Get.find<TaskController>();
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();

  String? _selectedPriority;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Normal'];

  @override
  void initState() {
    super.initState();
    taskController.isLoading.value = false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    DateTime initialDate = _selectedDate ?? DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    TimeOfDay initialTime = _selectedTime ?? TimeOfDay.now();
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        final hour = picked.hourOfPeriod.toString().padLeft(2, '0');
        final minute = picked.minute.toString().padLeft(2, '0');
        final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
        _timeController.text = "$hour:$minute $period";
      });
    }
  }

  Future<void> _createTask() async {
    debugPrint('Save button pressed');
    AppDevices.hideKeyboard(context);
    if (_formKey.currentState?.validate() ?? false) {
      debugPrint('Form valid, calling createTask');
      try {
        await taskController.createTask(
          _titleController.text.trim(),
          _descriptionController.text.trim(),
          priority: _selectedPriority ?? 'Normal',
          dueDate: _selectedDate != null && _selectedTime != null
              ? DateTime(
                  _selectedDate!.year,
                  _selectedDate!.month,
                  _selectedDate!.day,
                  _selectedTime!.hour,
                  _selectedTime!.minute,
                )
              : null,
        );
        debugPrint('createTask completed successfully');
        // Clear form on success
        _titleController.clear();
        _descriptionController.clear();
        _dateController.clear();
        _timeController.clear();
        setState(() {
          _selectedPriority = null;
          _selectedDate = null;
          _selectedTime = null;
        });
        // Navigate back
        Get.back();
      } catch (e) {
        debugPrint('Error in _createTask: $e');
        // Error is already shown by the controller
      }
    } else {
      debugPrint('Form invalid');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final isTablet = AppDevices.isTablet(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Text(
            "Create Task",
            style: AppStyles.sectionTitleStyle.copyWith(
              fontSize: isTablet ? AppSizes.titleLarge : AppSizes.titleNormal,
              color: Theme.of(context).colorScheme.onPrimary,
              fontFamily: 'raleway',
            ),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).canvasColor
            : Theme.of(context).colorScheme.primary,
        padding:
            EdgeInsets.all(isTablet ? AppSizes.medium * 2 : AppSizes.medium),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.small),
              ),
              elevation: 4,
              child: Container(
                width: isTablet ? 500 : double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSizes.medium,
                  horizontal: AppSizes.medium,
                ),
                decoration: BoxDecoration(
                  gradient: AppStyles.cardGradient,
                  borderRadius: BorderRadius.circular(AppSizes.small),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "New Task",
                        style: AppStyles.cardTitleStyle.copyWith(
                          fontSize: isTablet
                              ? AppSizes.titleSmall
                              : AppSizes.titleVerySmall,
                        ),
                      ),
                      const SizedBox(height: AppSizes.medium),

                      // Title Field
                      TextFormField(
                        controller: _titleController,
                        style: AppStyles.cardValueStyle.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: AppSizes.fontNormal,
                        ),
                        decoration: InputDecoration(
                          labelText: "Task Title",
                          labelStyle: TextStyle(
                            fontSize: AppSizes.fontSmall,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.small),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter a task title";
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSizes.small),

                      // Priority Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedPriority,
                        decoration: InputDecoration(
                          labelText: "Priority",
                          labelStyle: TextStyle(
                            fontSize: AppSizes.fontSmall,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.small),
                          ),
                        ),
                        items: _priorities
                            .map((priority) => DropdownMenuItem(
                                  value: priority,
                                  child: Text(priority),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPriority = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please select a priority";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSizes.small),

                      // Date and Time Picker Row
                      Row(
                        children: [
                          // Date Picker Field
                          Expanded(
                            child: TextFormField(
                              controller: _dateController,
                              readOnly: true,
                              style: AppStyles.cardValueStyle.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: AppSizes.fontSmall,
                              ),
                              decoration: InputDecoration(
                                labelText: "Due Date",
                                labelStyle: TextStyle(
                                  fontSize: AppSizes.fontVerySmall,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppSizes.small),
                                ),
                                suffixIcon: Icon(Icons.calendar_today,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                              onTap: () => _pickDate(context),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Select date";
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppSizes.small),
                          // Time Picker Field
                          Expanded(
                            child: TextFormField(
                              controller: _timeController,
                              readOnly: true,
                              style: AppStyles.cardValueStyle.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: AppSizes.fontSmall,
                              ),
                              decoration: InputDecoration(
                                labelText: "Time",
                                labelStyle: TextStyle(
                                  fontSize: AppSizes.fontVerySmall,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surface,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppSizes.small),
                                ),
                                suffixIcon: Icon(Icons.access_time,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                              onTap: () => _pickTime(context),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Select time";
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.small),

                      // Description Field
                      TextFormField(
                        controller: _descriptionController,
                        style: AppStyles.cardValueStyle.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: AppSizes.fontSmall,
                        ),
                        decoration: InputDecoration(
                          labelText: "Task Description",
                          labelStyle: TextStyle(
                            fontSize: AppSizes.fontVerySmall,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSizes.small),
                          ),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter a description";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSizes.medium),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: Obx(() => taskController.isLoading.value
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSizes.small,
                                  ),
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                                onPressed: _createTask,
                                child: Text(
                                  "Save",
                                  style: AppStyles.cardTitleStyle.copyWith(
                                    color: Colors.white,
                                    fontSize: AppSizes.fontNormal,
                                  ),
                                ),
                              )),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
