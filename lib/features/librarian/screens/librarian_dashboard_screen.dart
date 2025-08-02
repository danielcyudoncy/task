// features/librarian/screens/librarian_dashboard_screen.dart
// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:task/controllers/task_controller.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/features/librarian/widgets/task_list_view.dart';
import 'package:task/features/librarian/widgets/task_filters_sheet.dart';
import 'package:task/models/task_filters.dart';
import 'package:task/models/task_status_filter.dart';
import 'package:task/features/librarian/widgets/archive_stats_card.dart';
import 'package:task/theme/app_durations.dart';
import 'package:task/features/librarian/widgets/task_search_delegate.dart';
import 'package:task/service/export_service.dart';
import 'package:task/service/archive_service.dart';
import 'package:task/models/task_model.dart';

class LibrarianDashboardScreen extends StatefulWidget {
  const LibrarianDashboardScreen({super.key});

  @override
  State<LibrarianDashboardScreen> createState() => _LibrarianDashboardScreenState();
}

class _LibrarianDashboardScreenState extends State<LibrarianDashboardScreen> with SingleTickerProviderStateMixin {
  final TaskController _taskController = Get.find<TaskController>();
  final ExportService _exportService = Get.find<ExportService>();
  final ArchiveService _archiveService = Get.find<ArchiveService>();
  
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final RxString _searchQuery = ''.obs;
  final Rx<TaskFilters> _filters = TaskFilters().obs;
  final RxBool _showArchived = false.obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isRefreshing = false.obs;
  final RxMap<String, int> _archiveStats = <String, int>{}.obs;
  final RxString _archiveStatsError = ''.obs;
  final RxString _taskError = ''.obs;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeServices();
  }
  
  /// Initializes all required services
  Future<void> _initializeServices() async {
    try {
      _isLoading.value = true;
      
      // Initialize ArchiveService
      if (!Get.isRegistered<ArchiveService>()) {
        await Get.putAsync<ArchiveService>(() async {
          final service = ArchiveService();
          await service.initialize();
          return service;
        }, permanent: true);
      }
      
      // Initialize ExportService
      if (!Get.isRegistered<ExportService>()) {
        await Get.putAsync<ExportService>(() async {
          final service = ExportService();
          await service.initialize();
          return service;
        }, permanent: true);
      }
      
      // Load initial data
      await _loadArchiveStats();
    } catch (e) {
      _taskError.value = 'Failed to initialize services: $e';
      debugPrint('Service initialization error: $e');
    } finally {
      _isLoading.value = false;
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadArchiveStats() async {
    try {
      _isLoading.value = true;
      _archiveStatsError.value = '';
      _archiveStats.clear();
      
      final stats = await _archiveService.getArchiveStats().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timed out. Please check your internet connection.');
        },
      );
      
      _archiveStats.value = {
        'totalArchived': stats['totalArchived'] ?? 0,
        'archivedThisMonth': stats['archivedThisMonth'] ?? 0,
      };
    } on TimeoutException catch (e) {
      _archiveStatsError.value = e.message ?? 'Request timed out';
      _showErrorSnackbar('Network Error', 'Failed to load archive stats: ${e.message}');
    } catch (e) {
      _archiveStatsError.value = e.toString();
      _showErrorSnackbar('Error', 'Failed to load archive statistics');
    } finally {
      _isLoading.value = false;
    }
  }
  
  Future<void> _refreshData() async {
    try {
      _isRefreshing.value = true;
      _taskError.value = '';
      await Future.wait([
        _loadArchiveStats(),
        // Add other data refresh calls here if needed
      ]);
    } catch (e) {
      _taskError.value = e.toString();
      _showErrorSnackbar('Error', 'Failed to refresh data');
    } finally {
      _isRefreshing.value = false;
    }
  }
  
  void _showErrorSnackbar(String title, String message) {
    if (!mounted) return;
    
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
    );
  }
  
  Future<void> _showFilters() async {
    final result = await showModalBottomSheet<TaskFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskFiltersSheet(
        initialFilters: _filters.value,
      ),
    );
    
    if (result != null) {
      _filters.value = result;
    }
  }
  
  Future<void> _exportTasks() async {
    try {
      // Get tasks based on current filters
      List<Task> tasks = [];
      
      switch (_tabController.index) {
        case 0: // All tasks
          tasks = await _taskController.getAllTasks();
          break;
        case 1: // Completed
          final allTasks = await _taskController.getAllTasks();
          tasks = allTasks.where((task) => task.status.toLowerCase() == 'completed').toList();
          break;
        case 2: // Pending
          final allTasks = await _taskController.getAllTasks();
          tasks = allTasks.where((task) => task.status.toLowerCase() != 'completed').toList();
          break;
      }
      
      // Apply archive filter
      if (_showArchived.value) {
        tasks = tasks.where((task) => task.isArchived).toList();
      } else {
        tasks = tasks.where((task) => !task.isArchived).toList();
      }
      
      // Apply search filter
      if (_searchQuery.value.isNotEmpty) {
        final query = _searchQuery.value.toLowerCase();
        tasks = tasks.where((task) {
          return task.title.toLowerCase().contains(query) ||
              task.description.toLowerCase().contains(query) ||
              (task.category?.toLowerCase().contains(query) ?? false) ||
              task.tags.any((tag) => tag.toLowerCase().contains(query));
        }).toList();
      }
      
      // Apply additional filters
      if (_filters.value.hasActiveFilters) {
        tasks = _applyFilters(tasks, _filters.value);
      }
      
      if (tasks.isEmpty) {
        Get.snackbar(
          'No Tasks',
          'There are no tasks to export with the current filters.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      
      final exportType = await showModalBottomSheet<String>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('Export as PDF'),
                onTap: () => Navigator.of(context).pop('pdf'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.table_chart, color: Colors.green),
                title: const Text('Export as CSV'),
                onTap: () => Navigator.of(context).pop('csv'),
              ),
            ],
          ),
        ),
      );
      
      if (exportType == null) return;
      
      if (exportType == 'pdf') {
        final file = await _exportService.exportToPdf(tasks);
        await _exportService.shareFile(
          file,
          subject: 'Tasks Export - ${DateTime.now().toString().split(' ')[0]}',
          text: 'Here is the exported tasks list in PDF format.',
        );
      } else if (exportType == 'csv') {
        final file = await _exportService.exportToCsv(tasks);
        await _exportService.shareFile(
          file,
          subject: 'Tasks Export - ${DateTime.now().toString().split(' ')[0]}',
          text: 'Here is the exported tasks list in CSV format.',
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to export tasks: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  
  List<Task> _applyFilters(List<Task> tasks, TaskFilters filters) {
    if (!filters.hasActiveFilters) {
      return tasks;
    }
    
    return tasks.where((task) {
      // Status filter
      if (filters.statuses?.isNotEmpty == true) {
        if (!filters.statuses!.any((status) => 
            task.status.toLowerCase() == status.toLowerCase())) {
          return false;
        }
      }
      
      // Category filter
      if (filters.categories?.isNotEmpty == true && task.category != null) {
        if (!filters.categories!.any((category) => 
            task.category!.toLowerCase() == category.toLowerCase())) {
          return false;
        }
      }
      
      // Tags filter
      if (filters.tags?.isNotEmpty == true) {
        if (!filters.tags!.any((tag) => 
            task.tags.any((taskTag) => 
                taskTag.toLowerCase() == tag.toLowerCase()))) {
          return false;
        }
      }
      
      // Date range filter
      if (filters.startDate != null || filters.endDate != null) {
        if (filters.startDate != null && 
            task.timestamp.isBefore(filters.startDate!)) {
          return false;
        }
        
        if (filters.endDate != null && 
            task.timestamp.isAfter(filters.endDate!)) {
          return false;
        }
      }
      
      // Assigned users filter
      if (filters.assignedToUserIds?.isNotEmpty == true) {
        final assignedUserIds = [
          task.assignedReporterId,
          task.assignedCameramanId,
          task.assignedDriverId,
          task.assignedLibrarianId,
        ].whereType<String>().toList();
        
        if (!filters.assignedToUserIds!.any((userId) => 
            assignedUserIds.contains(userId))) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: colorScheme.primary,
          indicatorWeight: 3,
          labelStyle: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'All Tasks'),
            Tab(text: 'Completed'),
            Tab(text: 'Pending'),
          ],
          onTap: (index) {
            // Reset scroll position when changing tabs
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                0,
                duration: AppDurations.mediumAnimation,
                curve: Curves.easeOutCubic,
              );
            }
            
            // Haptic feedback
            HapticFeedback.lightImpact();
          },
        ),
        actions: [
          // Search button with loading state
          Obx(() => _isLoading.value
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Search tasks',
                  onPressed: () async {
                    try {
                      final query = await showSearch<String>(
                        context: context,
                        delegate: TaskSearchDelegate(),
                        query: _searchQuery.value,
                      );
                      
                      if (query != null) {
                        _searchQuery.value = query;
                      }
                    } catch (e) {
                      _showErrorSnackbar('Search Error', 'Failed to perform search');
                    }
                  },
                ),
          ),
          
          // Filter button with active indicator
          Obx(() => Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filter tasks',
                onPressed: _isLoading.value ? null : _showFilters,
              ),
              if (_filters.value.hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          )),
          
          // Export button with loading state
          Obx(() => _isLoading.value
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.ios_share),
                  tooltip: 'Export tasks',
                  onPressed: _exportTasks,
                ),
          ),
          
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              Get.find<AuthController>().logout();
            },
          ),
          
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: colorScheme.primary,
        backgroundColor: colorScheme.surface,
        strokeWidth: 2.5,
        edgeOffset: 0,
        triggerMode: RefreshIndicatorTriggerMode.anywhere,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Archive stats card
            SliverToBoxAdapter(
              child: Obx(() {
                final hasError = _archiveStatsError.value.isNotEmpty;
                final hasData = _archiveStats.isNotEmpty && !_isLoading.value && !hasError;
                
                return AnimatedSwitcher(
                  duration: AppDurations.mediumAnimation,
                  child: ArchiveStatsCard(
                    key: ValueKey(_showArchived.value),
                    totalArchived: hasData ? _archiveStats['totalArchived'] ?? 0 : 0,
                    archivedThisMonth: hasData ? _archiveStats['archivedThisMonth'] ?? 0 : 0,
                    onToggleArchive: () => _showArchived.toggle(),
                    showArchived: _showArchived.value,
                    isLoading: _isLoading.value,
                    error: hasError ? _archiveStatsError.value : null,
                  ),
                );
              }),
            ),
            
            // Error message if any
            Obx(() => _taskError.value.isNotEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Failed to load tasks',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colorScheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _taskError.value,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onErrorContainer.withOpacity(0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _refreshData,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.error,
                                foregroundColor: colorScheme.onError,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                textStyle: theme.textTheme.labelLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SliverToBoxAdapter(),
            ),
            
            // Task list
            SliverFillRemaining(
              hasScrollBody: false,
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // All tasks
                  TaskListView(
                    key: const ValueKey('all_tasks'),
                    statusFilter: TaskStatusFilter.all,
                    filters: _filters.value,
                    searchQuery: _searchQuery.value,
                    showArchived: _showArchived.value,
                    scrollController: _scrollController,
                    onError: (error) => _taskError.value = error,
                  ),
                  
                  // Completed tasks
                  TaskListView(
                    key: const ValueKey('completed_tasks'),
                    statusFilter: TaskStatusFilter.completed,
                    filters: _filters.value,
                    searchQuery: _searchQuery.value,
                    showArchived: _showArchived.value,
                    scrollController: _scrollController,
                    onError: (error) => _taskError.value = error,
                  ),
                  
                  // Pending tasks
                  TaskListView(
                    key: const ValueKey('pending_tasks'),
                    statusFilter: TaskStatusFilter.pending,
                    filters: _filters.value,
                    searchQuery: _searchQuery.value,
                    showArchived: _showArchived.value,
                    scrollController: _scrollController,
                    onError: (error) => _taskError.value = error,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
