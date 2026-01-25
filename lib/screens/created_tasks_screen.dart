// screens/created_tasks_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:task/models/task.dart';
import 'package:task/widgets/minimal_task_card.dart';
import 'package:task/widgets/task_detail_modal.dart';
import 'package:task/widgets/empty_state_widget.dart';

class CreatedTasksScreen extends StatefulWidget {
  const CreatedTasksScreen({super.key});

  @override
  State<CreatedTasksScreen> createState() => _CreatedTasksScreenState();
}

class _CreatedTasksScreenState extends State<CreatedTasksScreen> {
  final TaskController taskController = Get.find<TaskController>();
  final AuthController authController = Get.find<AuthController>();
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  final RxList<Task> _filteredTasks = <Task>[].obs;
  
  // Calendar State
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Task>> _tasksByDay = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _searchController.addListener(() => _searchQuery.value = _searchController.text);

    // Initial filter
    _filterTasks();

    // Listen to task list changes
    ever(taskController.tasks, (_) {
      _filterTasks();
    });

    // Listen to search query changes for real-time filtering
    ever(_searchQuery, (_) {
      _filterTasks();
    });
  }

  // Normalize date to remove time component for comparison
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _filterTasks() {
    final userId = authController.currentUser?.uid;
    if (userId == null) return;

    // First get all tasks created by user
    final allUserTasks = taskController.tasks.where((task) {
      return task.createdById == userId;
    }).toList();

    // Group tasks by date
    _tasksByDay = {};
    for (var task in allUserTasks) {
      final date = _normalizeDate(task.timestamp);
      if (_tasksByDay[date] == null) {
        _tasksByDay[date] = [];
      }
      _tasksByDay[date]!.add(task);
    }

    // Then filter based on selection and search
    final filteredTasks = allUserTasks.where((task) {
      // Date filter
      if (_selectedDay != null) {
        final taskDate = _normalizeDate(task.timestamp);
        final selectedDate = _normalizeDate(_selectedDay!);
        if (taskDate != selectedDate) return false;
      }

      // Search filter
      final searchLower = _searchQuery.value.toLowerCase();
      if (searchLower.isEmpty) return true;

      return task.title.toLowerCase().contains(searchLower) ||
          task.description.toLowerCase().contains(searchLower) ||
          task.status.toLowerCase().contains(searchLower) ||
          (task.category?.toLowerCase().contains(searchLower) ?? false) ||
          (task.priority?.toLowerCase().contains(searchLower) ?? false) ||
          task.tags.any((tag) => tag.toLowerCase().contains(searchLower));
    }).toList();

    // Sort by newest first
    filteredTasks.sort((a, b) {
      final dateA = a.timestamp;
      final dateB = b.timestamp;
      return dateB.compareTo(dateA);
    });

    _filteredTasks.assignAll(filteredTasks);
  }

  List<Task> _getTasksForDay(DateTime day) {
    return _tasksByDay[_normalizeDate(day)] ?? [];
  }

  void _showTaskDetail(Task task) {
    Get.find<SettingsController>().triggerFeedback();
    showDialog(
      context: context,
      builder: (context) => TaskDetailModal(
        task: task,
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Tasks Created by Me',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
            fontSize: 20.sp,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _calendarFormat == CalendarFormat.week 
                  ? Icons.calendar_view_month 
                  : Icons.calendar_view_week,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () {
              setState(() {
                _calendarFormat = _calendarFormat == CalendarFormat.week 
                    ? CalendarFormat.month 
                    : CalendarFormat.week;
              });
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Modern Calendar
                Container(
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF292B3A) : Colors.white,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                      _filterTasks();
                    },
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      }
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    eventLoader: _getTasksForDay,
                    calendarStyle: CalendarStyle(
                      // Use markers to show dots for days with tasks
                      markerSize: 6,
                      markerDecoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      defaultTextStyle: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      weekendTextStyle: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      // Custom builder for days with tasks to make text blue as requested
                      defaultBuilder: (context, day, focusedDay) {
                        final hasTasks = _getTasksForDay(day).isNotEmpty;
                        if (hasTasks) {
                          return Center(
                            child: Container(
                              decoration: BoxDecoration(
                                // Optional: Add a subtle background or border
                              ),
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: Colors.blue, // "date will be blue in color"
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ),
                          );
                        }
                        return null; // Use default
                      },
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      leftChevronIcon: Icon(
                        Icons.chevron_left,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      rightChevronIcon: Icon(
                        Icons.chevron_right,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),

                // Search Bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search in ${_selectedDay != null ? DateFormat('MMM d').format(_selectedDay!) : 'all tasks'}...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF292B3A) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12.h,
                        horizontal: 16.w,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                      ),
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                
                // Selected Date Header
                if (_selectedDay != null)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            DateFormat('EEEE, MMMM d, y').format(_selectedDay!),
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Obx(() => Text(
                            '${_filteredTasks.length} Tasks',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            ),
                          )),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Task List
          Obx(() {
            if (_filteredTasks.isEmpty) {
              if (_searchQuery.value.isNotEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        SizedBox(height: 16.h),
                        Text(
                          'No tasks found matching "${_searchQuery.value}"',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateWidget(
                  title: "No Tasks",
                  message: "No tasks created on ${DateFormat('MMM d').format(_selectedDay!)}",
                  icon: Icons.event_busy,
                ),
              );
            }

            return SliverPadding(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = _filteredTasks[index];
                    return MinimalTaskCard(
                      key: ValueKey(task.taskId),
                      task: task,
                      isDark: isDark,
                      onTap: () => _showTaskDetail(task),
                      enableSwipeToDelete: false,
                    );
                  },
                  childCount: _filteredTasks.length,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
