// views/task_creation_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/task_controller.dart';
import 'package:task/utils/constants/app_styles.dart';
import 'package:task/utils/constants/app_sizes.dart';
import 'package:task/utils/devices/app_devices.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
  final _tagsController = TextEditingController();
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
  ];

  String? _selectedPriority;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final List<String> _priorities = ['Low', 'Medium', 'High', 'Normal'];

  @override
  void initState() {
    super.initState();
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
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
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
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white 
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
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
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
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
          category: _selectedCategory,
          tags: _tagsController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        );
        debugPrint('createTask completed successfully');
        // Wait for taskController to finish loading
        while (taskController.isLoading.value) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        // Dismiss loading dialog
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        // Clear form on success
        _titleController.clear();
        _descriptionController.clear();
        _dateController.clear();
        _timeController.clear();
        _tagsController.clear();
        setState(() {
          _selectedPriority = null;
          _selectedDate = null;
          _selectedTime = null;
          _selectedCategory = null;
        });
        // Navigate back to appropriate screen based on user role
        final userRole = taskController.authController.userRole.value;
        if (["Admin", "Assignment Editor", "Head of Department"].contains(userRole)) {
          Get.offAllNamed('/admin-dashboard');
        } else {
          Get.offAllNamed('/home');
        }
      } catch (e) {
        // Dismiss loading dialog if error
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
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
                  Padding(
                    padding: const EdgeInsets.only(top: 32.0, bottom: 24.0),
                    child: Text(
                      "Create Task",
                      style: AppStyles.sectionTitleStyle.copyWith(
                        fontSize: isTablet ? AppSizes.titleLarge.sp : AppSizes.titleNormal.sp,
                        color: colorScheme.onPrimary,
                        fontFamily: 'raleway',
                      ),
                    ),
                  ),
                  Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    color: Theme.of(context).colorScheme.surface, // Use theme surface color
                    child: Container(
                      width: isTablet ? 500.w : MediaQuery.of(context).size.width * 0.95,
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
                                fillColor: Theme.of(context).brightness == Brightness.dark ? Color(0xFF232323) : Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
                                prefixIcon: const Icon(Icons.description_rounded),
                                labelStyle: TextStyle(
                                  fontSize: 14.sp,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                filled: true,
                                fillColor: Theme.of(context).brightness == Brightness.dark ? Color(0xFF232323) : Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
                              value: _selectedPriority,
                              decoration: InputDecoration(
                                labelText: "Priority",
                                prefixIcon: const Icon(Icons.flag_rounded),
                                labelStyle: TextStyle(
                                  fontSize: 14.sp,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                filled: true,
                                fillColor: Theme.of(context).brightness == Brightness.dark ? Color(0xFF232323) : Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
                            const SizedBox(height: 16),
                            // Date and Time Picker Row
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
                                      prefixIcon: const Icon(Icons.calendar_today_rounded),
                                      labelStyle: TextStyle(
                                        fontSize: 14.sp,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      filled: true,
                                      fillColor: Theme.of(context).brightness == Brightness.dark ? Color(0xFF232323) : Color(0xFFF5F5F5),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
                                      prefixIcon: const Icon(Icons.access_time_rounded),
                                      labelStyle: TextStyle(
                                        fontSize: 14.sp,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      filled: true,
                                      fillColor: Theme.of(context).brightness == Brightness.dark ? Color(0xFF232323) : Color(0xFFF5F5F5),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
                            const SizedBox(height: 16),
                            // Category Dropdown
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedCategory,
                                    decoration: InputDecoration(
                                      labelText: "Category",
                                      prefixIcon: const Icon(Icons.category_rounded),
                                      filled: true,
                                      fillColor: Theme.of(context).brightness == Brightness.dark ? Color(0xFF232323) : Color(0xFFF5F5F5),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                      labelStyle: TextStyle(
                                        fontSize: 14.sp,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    items: _categories
                                        .map((category) => DropdownMenuItem<String>(
                                              value: category,
                                              child: Text(
                                                category,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontSize: 14.sp),
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCategory = value;
                                      });
                                    },
                                    validator: (value) => value == null ? 'Please select a category' : null,
                                  ),
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
                                fillColor: Theme.of(context).brightness == Brightness.dark ? Color(0xFF232323) : Color(0xFFF5F5F5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                              ),
                              maxLines: 2,
                              validator: (value) {
                                // Optional, but you can require at least one tag if desired
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),
                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              child: Obx(() => taskController.isLoading.value
                                  ? const Center(child: CircularProgressIndicator())
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 18.h,
                                        ),
                                        backgroundColor: colorScheme.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
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
