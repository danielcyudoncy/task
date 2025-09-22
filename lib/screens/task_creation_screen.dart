// screens/task_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/task_controller.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as dtp;
import 'package:task/utils/devices/app_devices.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/task_model.dart';

class TaskCreationScreen extends StatefulWidget {
  final Task? task;
  const TaskCreationScreen({super.key, this.task});

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
  final _tagsController = TextEditingController();
  final _commentsController = TextEditingController();
  final _customCategoryController =
      TextEditingController(); // Added for custom category
  String? _selectedCategory;
  final List<String> _categories = [
    'Political',
    'Government Announcement',
    'Music Festival',
    'Art Exhibition or Gallery Opening',
    'Tech Conference',
    'Protest or Demonstration',
    'Award Ceremony',
    'Natural Disaster',
    'Sports Match or Tournament',
    'Religious Festival or Gathering',
    'In-house Program',
    'Live TV Talk Show',
    'Documentary Screening',
    'Local Community Event',
    'Fashion Show',
    'Book Launch',
    'Business Summit / Expo',
    'School or University Function',
    'NGO or Charity Event',
    'Product Launch Event',
    '#BreakingNews',
    'FieldReport',
    'StudioCoverage',
    'FeatureStory',
    'LiveBroadcast',
    'Culture',
    'Politics',
    'HumanInterest',
    'Others',
  ];

  String? _selectedPriority;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isOthersSelected = false; // Track if "Others" is selected

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Normal'];

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;

      // Check if task has a custom category
      if (widget.task!.category != null &&
          !_categories.contains(widget.task!.category)) {
        _selectedCategory = 'Others';
        _customCategoryController.text = widget.task!.category!;
        _isOthersSelected = true;
      } else {
        _selectedCategory = widget.task!.category;
      }

      // ... populate other fields from the task object
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      taskController.isLoading.value = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _tagsController.dispose();
    _commentsController.dispose();
    _customCategoryController.dispose(); // Dispose custom category controller
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    dtp.DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      minTime: DateTime.now(),
      maxTime: DateTime(2100, 12, 31),
      currentTime: _selectedDate ?? DateTime.now(),
      theme: dtp.DatePickerTheme(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF232323)
            : Colors.white,
        itemStyle: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
        doneStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18.sp,
          letterSpacing: 1.1,
          backgroundColor: Theme.of(context).colorScheme.primary,
          shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
        cancelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
          fontSize: 16.sp,
        ),
        containerHeight: 350,
        itemHeight: 48.0,
        titleHeight: 60.0,
      ),
      onConfirm: (picked) {
        setState(() {
          _selectedDate = picked;
          _dateController.text =
              "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
        });
      },
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    dtp.DatePicker.showTimePicker(
      context,
      showTitleActions: true,
      currentTime: _selectedTime != null
          ? DateTime(0, 0, 0, _selectedTime!.hour, _selectedTime!.minute)
          : DateTime.now(),
      theme: dtp.DatePickerTheme(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF232323)
            : Colors.white,
        itemStyle: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
        doneStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18.sp,
          letterSpacing: 1.1,
          backgroundColor: Theme.of(context).colorScheme.primary,
          shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
        cancelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
          fontSize: 16.sp,
        ),
        containerHeight: 350,
        itemHeight: 48.0,
        titleHeight: 60.0,
      ),
      onConfirm: (picked) {
        setState(() {
          _selectedTime = TimeOfDay(hour: picked.hour, minute: picked.minute);
          final hour = (picked.hour % 12 == 0 ? 12 : picked.hour % 12)
              .toString()
              .padLeft(2, '0');
          final minute = picked.minute.toString().padLeft(2, '0');
          final period = picked.hour < 12 ? 'AM' : 'PM';
          _timeController.text = "$hour:$minute $period";
        });
      },
    );
  }

  Future<void> _createTask(BuildContext context) async {
    debugPrint('Save button pressed');
    AppDevices.hideKeyboard(context);
    if (_formKey.currentState?.validate() ?? false) {
      debugPrint('Form valid, calling createTask');
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        // Determine the category to use
        String? finalCategory = _selectedCategory;
        if (_selectedCategory == 'Others') {
          finalCategory = _customCategoryController.text.trim().isEmpty
              ? null
              : _customCategoryController.text.trim();
        }

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
          category: finalCategory,
          tags: _tagsController.text
              .trim()
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          comments: _commentsController.text.trim().isNotEmpty
              ? _commentsController.text.trim()
              : null,
        );
        debugPrint('createTask completed successfully');
        // Wait for taskController to finish loading
        while (taskController.isLoading.value) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        // Dismiss loading dialog
        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        // Clear form on success
        _titleController.clear();
        _descriptionController.clear();
        _dateController.clear();
        _timeController.clear();
        _tagsController.clear();
        _commentsController.clear();
        _customCategoryController.clear();
        setState(() {
          _selectedPriority = null;
          _selectedDate = null;
          _selectedTime = null;
          _selectedCategory = null;
          _isOthersSelected = false;
        });
        // Correct navigation logic after task creation
        final userRole = taskController.authController.userRole.value;
        if ([
          "Admin",
          "Assignment Editor",
          "Head of Department",
          "Head of Unit",
          "News Director",
          "Assistant News Director"
        ].contains(userRole)) {
          Get.offAllNamed('/admin-dashboard');
        } else if (userRole == "Librarian") {
          Get.offAllNamed('/librarian-dashboard');
        } else {
          Get.offAllNamed('/home');
        }
      } catch (e) {
        // Dismiss loading dialog if error
        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        debugPrint('Error creating task: $e');
        Get.snackbar('Error', 'Failed to create task: $e');
      }
    } else {
      debugPrint('Form invalid');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = AppDevices.isTablet(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.task != null ? 'Edit Task' : 'Create Task',
          style: TextStyle(color: colorScheme.onPrimary),
        ),
        backgroundColor: colorScheme.primary,
      ),
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 32.h),
                  Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    color: Theme.of(context)
                        .colorScheme
                        .surface, // Use theme surface color
                    child: Container(
                      width: isTablet
                          ? 500.w
                          : MediaQuery.of(context).size.width * 0.95,
                      padding: EdgeInsets.symmetric(
                        vertical: 32.h,
                        horizontal: isTablet ? 36.w : 20.w,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Section: Task Details
                            Text(
                              "Task Details",
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 18),
                            // Title Field
                            TextFormField(
                              controller: _titleController,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 16.sp,
                                fontFamily: 'Raleway',
                              ),
                              decoration: InputDecoration(
                                labelText: "Task Title",
                                prefixIcon: const Icon(Icons.title_rounded),
                                labelStyle: TextStyle(
                                  fontSize: 14.sp,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                filled: true,
                                fillColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Color(0xFF232323)
                                    : Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 12),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Please enter a task title";
                                }
                                return null;
                              },
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),
                            // Description Field
                            TextFormField(
                              controller: _descriptionController,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 15.sp,
                                fontFamily: 'Raleway',
                              ),
                              decoration: InputDecoration(
                                labelText: "Task Description",
                                prefixIcon:
                                    const Icon(Icons.description_rounded),
                                labelStyle: TextStyle(
                                  fontSize: 14.sp,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                filled: true,
                                fillColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Color(0xFF232323)
                                    : Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 12),
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Please enter a description";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            // Section: Meta
                            Text(
                              "Meta",
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 18),
                            // Priority Dropdown
                            DropdownButtonFormField<String>(
                              initialValue: _selectedPriority,
                              dropdownColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFF232323)
                                  : null,
                              decoration: InputDecoration(
                                labelText: "Priority",
                                prefixIcon: const Icon(Icons.flag_rounded),
                                labelStyle: TextStyle(
                                  fontSize: 14.sp,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                filled: true,
                                fillColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Color(0xFF232323)
                                    : Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 12),
                              ),
                              items: _priorities
                                  .map((priority) => DropdownMenuItem(
                                        value: priority,
                                        child: Text(
                                          priority,
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : null,
                                          ),
                                        ),
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
                            const SizedBox(height: 16),
                            // Date and Time Picker Row
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Date Picker Field
                                    Expanded(
                                      child: TextFormField(
                                        controller: _dateController,
                                        readOnly: true,
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontSize: 15.sp,
                                          fontFamily: 'Raleway',
                                        ),
                                        decoration: InputDecoration(
                                          labelText: "Due Date",
                                          prefixIcon: const Icon(
                                              Icons.calendar_today_rounded),
                                          labelStyle: TextStyle(
                                            fontSize: 14.sp,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          filled: true,
                                          fillColor:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Color(0xFF232323)
                                                  : Color(0xFFF5F5F5),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: BorderSide.none,
                                          ),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 12),
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
                                    const SizedBox(width: 12),
                                    // Time Picker Field
                                    Expanded(
                                      child: TextFormField(
                                        controller: _timeController,
                                        readOnly: true,
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontSize: 15.sp,
                                          fontFamily: 'Raleway',
                                        ),
                                        decoration: InputDecoration(
                                          labelText: "Time",
                                          prefixIcon: const Icon(
                                              Icons.access_time_rounded),
                                          labelStyle: TextStyle(
                                            fontSize: 14.sp,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                          filled: true,
                                          fillColor:
                                              Theme.of(context).brightness ==
                                                      Brightness.dark
                                                  ? Color(0xFF232323)
                                                  : Color(0xFFF5F5F5),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            borderSide: BorderSide.none,
                                          ),
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 12),
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
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Category Dropdown
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedCategory,
                                    dropdownColor:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(0xFF232323)
                                            : null,
                                    items: _categories
                                        .map((category) =>
                                            DropdownMenuItem<String>(
                                              value: category,
                                              child: Container(
                                                width: double.infinity,
                                                constraints: BoxConstraints(
                                                  maxWidth:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          0.7,
                                                ),
                                                child: Text(
                                                  category,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: isTablet ? 2 : 1,
                                                  style: TextStyle(
                                                    fontSize: isTablet
                                                        ? 14.sp
                                                        : 13.sp,
                                                    fontFamily: 'Raleway',
                                                  ),
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                    decoration: InputDecoration(
                                      labelText: "Category",
                                      labelStyle: TextStyle(
                                        fontSize: 14.sp,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      filled: true,
                                      fillColor: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Color(0xFF232323)
                                          : Color(0xFFF5F5F5),
                                    ),
                                    menuMaxHeight:
                                        MediaQuery.of(context).size.height *
                                            0.4,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCategory = value;
                                        _isOthersSelected = (value == 'Others');
                                        // Clear custom category when switching away from "Others"
                                        if (!_isOthersSelected) {
                                          _customCategoryController.clear();
                                        }
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null) {
                                        return 'Please select a category';
                                      }
                                      if (value == 'Others' &&
                                          _customCategoryController.text
                                              .trim()
                                              .isEmpty) {
                                        return 'Please specify the custom category';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            // Custom Category Field (shown when "Others" is selected)
                            if (_isOthersSelected)
                              Column(
                                children: [
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _customCategoryController,
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 15.sp,
                                      fontFamily: 'Raleway',
                                    ),
                                    decoration: InputDecoration(
                                      labelText: "Specify Category",
                                      prefixIcon:
                                          const Icon(Icons.edit_note_rounded),
                                      labelStyle: TextStyle(
                                        fontSize: 14.sp,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      filled: true,
                                      fillColor: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Color(0xFF232323)
                                          : Color(0xFFF5F5F5),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 12, horizontal: 12),
                                    ),
                                    validator: (value) {
                                      if (_isOthersSelected &&
                                          (value == null ||
                                              value.trim().isEmpty)) {
                                        return 'Please specify the custom category';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),
                            // Tags/Keywords Field
                            TextFormField(
                              controller: _tagsController,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 15.sp,
                                fontFamily: 'Raleway',
                              ),
                              decoration: InputDecoration(
                                labelText: "Tags/Keywords (comma separated)",
                                prefixIcon: const Icon(Icons.tag_rounded),
                                labelStyle: TextStyle(
                                  fontSize: 14.sp,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                filled: true,
                                fillColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Color(0xFF232323)
                                    : Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 12),
                              ),
                              maxLines: 2,
                              validator: (value) {
                                // Optional, but you can require at least one tag if desired
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Comments Field
                            TextFormField(
                              controller: _commentsController,
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 15.sp,
                                fontFamily: 'Raleway',
                              ),
                              decoration: InputDecoration(
                                labelText: "Comments (optional)",
                                prefixIcon: const Icon(Icons.comment_rounded),
                                labelStyle: TextStyle(
                                  fontSize: 14.sp,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                filled: true,
                                fillColor: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Color(0xFF232323)
                                    : Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 12),
                              ),
                              maxLines: 3,
                              minLines: 2,
                              textInputAction: TextInputAction.newline,
                            ),
                            const SizedBox(height: 28),
                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              child: Obx(() => taskController.isLoading.value
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 18.h,
                                        ),
                                        backgroundColor:
                                            const Color(0xFF2F80ED),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        elevation: 2,
                                      ),
                                      onPressed: () => _createTask(context),
                                      child: Text(
                                        "Save",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Raleway',
                                          letterSpacing: 1.1,
                                        ),
                                      ),
                                    )),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
