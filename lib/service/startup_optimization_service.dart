import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StartupPhase {
  initial,
  critical,
  essential,
  optional,
  background,
  completed
}

class StartupTask {
  final String id;
  final String name;
  final StartupPhase phase;
  final Future<void> Function() task;
  final List<String> dependencies;
  final Duration? timeout;
  final bool canRunInBackground;
  
  StartupTask({
    required this.id,
    required this.name,
    required this.phase,
    required this.task,
    this.dependencies = const [],
    this.timeout,
    this.canRunInBackground = false,
  });
}

class StartupMetrics {
  final DateTime startTime;
  final DateTime? endTime;
  final Map<String, Duration> taskDurations;
  final Map<String, String?> taskErrors;
  final Duration totalDuration;
  
  StartupMetrics({
    required this.startTime,
    this.endTime,
    required this.taskDurations,
    required this.taskErrors,
    required this.totalDuration,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'totalDuration': totalDuration.inMilliseconds,
      'taskDurations': taskDurations.map(
        (key, value) => MapEntry(key, value.inMilliseconds),
      ),
      'taskErrors': taskErrors,
    };
  }
}

class StartupOptimizationService extends GetxService {
  static StartupOptimizationService get to => Get.find();
  
  final List<StartupTask> _tasks = [];
  final Map<String, bool> _completedTasks = {};
  final Map<String, Duration> _taskDurations = {};
  final Map<String, String?> _taskErrors = {};
  final Set<String> _runningTasks = {};
  
  final Rx<StartupPhase> _currentPhase = StartupPhase.initial.obs;
  final RxBool _isStartupComplete = false.obs;
  final RxDouble _startupProgress = 0.0.obs;
  final RxString _currentTaskName = ''.obs;
  
  DateTime? _startupStartTime;
  DateTime? _startupEndTime;
  SharedPreferences? _prefs;
  
  // Getters
  StartupPhase get currentPhase => _currentPhase.value;
  bool get isStartupComplete => _isStartupComplete.value;
  double get startupProgress => _startupProgress.value;
  String get currentTaskName => _currentTaskName.value;
  
  // Observables
  Rx<StartupPhase> get currentPhaseObs => _currentPhase;
  RxBool get isStartupCompleteObs => _isStartupComplete;
  RxDouble get startupProgressObs => _startupProgress;
  RxString get currentTaskNameObs => _currentTaskName;
  
  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializePreferences();
    _registerDefaultTasks();
  }
  
  Future<void> _initializePreferences() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing preferences: $e');
      }
    }
  }
  
  void _registerDefaultTasks() {
    // Critical tasks - must complete before app is usable
    registerTask(StartupTask(
      id: 'firebase_init',
      name: 'Initialize Firebase',
      phase: StartupPhase.critical,
      task: () async {
        // Firebase initialization is handled in bootstrap
        await Future.delayed(const Duration(milliseconds: 100));
      },
      timeout: const Duration(seconds: 10),
    ));
    
    registerTask(StartupTask(
      id: 'auth_check',
      name: 'Check Authentication',
      phase: StartupPhase.critical,
      task: () async {
        // Auth check is handled in bootstrap
        await Future.delayed(const Duration(milliseconds: 50));
      },
      dependencies: ['firebase_init'],
      timeout: const Duration(seconds: 5),
    ));
    
    // Essential tasks - needed for core functionality
    registerTask(StartupTask(
      id: 'user_cache',
      name: 'Load User Cache',
      phase: StartupPhase.essential,
      task: () async {
        // User cache loading is handled in bootstrap
        await Future.delayed(const Duration(milliseconds: 200));
      },
      dependencies: ['auth_check'],
      timeout: const Duration(seconds: 3),
    ));
    
    registerTask(StartupTask(
      id: 'theme_init',
      name: 'Initialize Theme',
      phase: StartupPhase.essential,
      task: () async {
        // Theme initialization is handled in bootstrap
        await Future.delayed(const Duration(milliseconds: 100));
      },
      timeout: const Duration(seconds: 2),
    ));
    
    // Optional tasks - enhance user experience but not critical
    registerTask(StartupTask(
      id: 'preload_assets',
      name: 'Preload Assets',
      phase: StartupPhase.optional,
      task: () async {
        await _preloadCriticalAssets();
      },
      canRunInBackground: true,
      timeout: const Duration(seconds: 5),
    ));
    
    registerTask(StartupTask(
      id: 'warm_caches',
      name: 'Warm Up Caches',
      phase: StartupPhase.optional,
      task: () async {
        await _warmUpCaches();
      },
      canRunInBackground: true,
      timeout: const Duration(seconds: 3),
    ));
    
    // Background tasks - run after app is ready
    registerTask(StartupTask(
      id: 'analytics_init',
      name: 'Initialize Analytics',
      phase: StartupPhase.background,
      task: () async {
        // Analytics initialization
        await Future.delayed(const Duration(milliseconds: 500));
      },
      canRunInBackground: true,
      timeout: const Duration(seconds: 10),
    ));
    
    registerTask(StartupTask(
      id: 'background_sync',
      name: 'Background Data Sync',
      phase: StartupPhase.background,
      task: () async {
        // Background data synchronization
        await Future.delayed(const Duration(seconds: 1));
      },
      dependencies: ['user_cache'],
      canRunInBackground: true,
      timeout: const Duration(seconds: 30),
    ));
  }
  
  void registerTask(StartupTask task) {
    _tasks.add(task);
  }
  
  Future<void> executeStartup() async {
    if (_startupStartTime != null) {
      if (kDebugMode) {
        print('Startup already in progress or completed');
      }
      return;
    }
    
    _startupStartTime = DateTime.now();
    _currentPhase.value = StartupPhase.initial;
    
    try {
      // Execute tasks by phase
      await _executePhase(StartupPhase.critical);
      await _executePhase(StartupPhase.essential);
      await _executePhase(StartupPhase.optional);
      
      // Mark startup as complete for UI
      _isStartupComplete.value = true;
      _currentPhase.value = StartupPhase.completed;
      _startupProgress.value = 1.0;
      
      // Continue with background tasks
      _executeBackgroundTasks();
      
      _startupEndTime = DateTime.now();
      await _saveStartupMetrics();
      
      if (kDebugMode) {
        final duration = _startupEndTime!.difference(_startupStartTime!);
        print('Startup completed in ${duration.inMilliseconds}ms');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Startup failed: $e');
      }
      rethrow;
    }
  }
  
  Future<void> _executePhase(StartupPhase phase) async {
    _currentPhase.value = phase;
    
    final phaseTasks = _tasks.where((task) => task.phase == phase).toList();
    if (phaseTasks.isEmpty) return;
    
    // Sort tasks by dependencies
    final sortedTasks = _topologicalSort(phaseTasks);
    
    for (int i = 0; i < sortedTasks.length; i++) {
      final task = sortedTasks[i];
      
      // Update progress
      final phaseProgress = (i + 1) / sortedTasks.length;
      final overallProgress = _calculateOverallProgress(phase, phaseProgress);
      _startupProgress.value = overallProgress;
      _currentTaskName.value = task.name;
      
      await _executeTask(task);
    }
  }
  
  void _executeBackgroundTasks() {
    final backgroundTasks = _tasks.where(
      (task) => task.phase == StartupPhase.background,
    ).toList();
    
    // Execute background tasks without blocking
    for (final task in backgroundTasks) {
      _executeTask(task).catchError((error) {
        if (kDebugMode) {
          print('Background task ${task.id} failed: $error');
        }
      });
    }
  }
  
  Future<void> _executeTask(StartupTask task) async {
    if (_completedTasks[task.id] == true || _runningTasks.contains(task.id)) {
      return;
    }
    
    // Check dependencies
    for (final dependency in task.dependencies) {
      if (_completedTasks[dependency] != true) {
        if (kDebugMode) {
          print('Task ${task.id} waiting for dependency: $dependency');
        }
        return;
      }
    }
    
    _runningTasks.add(task.id);
    final stopwatch = Stopwatch()..start();
    
    try {
      if (task.timeout != null) {
        await task.task().timeout(task.timeout!);
      } else {
        await task.task();
      }
      
      _completedTasks[task.id] = true;
      _taskErrors[task.id] = null;
      
    } catch (e) {
      _completedTasks[task.id] = false;
      _taskErrors[task.id] = e.toString();
      
      if (kDebugMode) {
        print('Task ${task.id} failed: $e');
      }
      
      // Don't rethrow for background tasks
      if (task.phase != StartupPhase.background) {
        rethrow;
      }
    } finally {
      stopwatch.stop();
      _taskDurations[task.id] = stopwatch.elapsed;
      _runningTasks.remove(task.id);
    }
  }
  
  List<StartupTask> _topologicalSort(List<StartupTask> tasks) {
    final result = <StartupTask>[];
    final visited = <String>{};
    final visiting = <String>{};
    
    void visit(StartupTask task) {
      if (visiting.contains(task.id)) {
        throw Exception('Circular dependency detected: ${task.id}');
      }
      
      if (visited.contains(task.id)) {
        return;
      }
      
      visiting.add(task.id);
      
      for (final depId in task.dependencies) {
        final depTask = tasks.firstWhereOrNull((t) => t.id == depId);
        if (depTask != null) {
          visit(depTask);
        }
      }
      
      visiting.remove(task.id);
      visited.add(task.id);
      result.add(task);
    }
    
    for (final task in tasks) {
      if (!visited.contains(task.id)) {
        visit(task);
      }
    }
    
    return result;
  }
  
  double _calculateOverallProgress(StartupPhase currentPhase, double phaseProgress) {
    const phaseWeights = {
      StartupPhase.critical: 0.4,
      StartupPhase.essential: 0.4,
      StartupPhase.optional: 0.2,
    };
    
    double progress = 0.0;
    
    // Add completed phases
    if (currentPhase.index > StartupPhase.critical.index) {
      progress += phaseWeights[StartupPhase.critical]!;
    }
    if (currentPhase.index > StartupPhase.essential.index) {
      progress += phaseWeights[StartupPhase.essential]!;
    }
    
    // Add current phase progress
    final currentWeight = phaseWeights[currentPhase] ?? 0.0;
    progress += currentWeight * phaseProgress;
    
    return progress.clamp(0.0, 1.0);
  }
  
  Future<void> _preloadCriticalAssets() async {
    // Preload commonly used images, fonts, etc.
    // This is a placeholder - implement based on your app's assets
    await Future.delayed(const Duration(milliseconds: 500));
  }
  
  Future<void> _warmUpCaches() async {
    // Warm up frequently accessed caches
    // This is a placeholder - implement based on your app's caching needs
    await Future.delayed(const Duration(milliseconds: 300));
  }
  
  Future<void> _saveStartupMetrics() async {
    if (_prefs == null || _startupStartTime == null) return;
    
    try {
      final metrics = StartupMetrics(
        startTime: _startupStartTime!,
        endTime: _startupEndTime,
        taskDurations: Map.from(_taskDurations),
        taskErrors: Map.from(_taskErrors),
        totalDuration: _startupEndTime?.difference(_startupStartTime!) ?? Duration.zero,
      );
      
      await _prefs!.setString('startup_metrics', metrics.toJson().toString());
      
      // Keep only last 10 startup metrics
      final previousMetrics = _prefs!.getStringList('startup_history') ?? [];
      previousMetrics.add(metrics.toJson().toString());
      if (previousMetrics.length > 10) {
        previousMetrics.removeAt(0);
      }
      await _prefs!.setStringList('startup_history', previousMetrics);
      
    } catch (e) {
      if (kDebugMode) {
        print('Error saving startup metrics: $e');
      }
    }
  }
  
  // Public methods for monitoring
  StartupMetrics? getLastStartupMetrics() {
    if (_startupStartTime == null) return null;
    
    return StartupMetrics(
      startTime: _startupStartTime!,
      endTime: _startupEndTime,
      taskDurations: Map.from(_taskDurations),
      taskErrors: Map.from(_taskErrors),
      totalDuration: _startupEndTime?.difference(_startupStartTime!) ?? Duration.zero,
    );
  }
  
  List<StartupMetrics> getStartupHistory() {
    if (_prefs == null) return [];
    
    try {
      final history = _prefs!.getStringList('startup_history') ?? [];
      return history.map((json) {
        // Parse JSON and create StartupMetrics
        // This is a simplified version - you'd need proper JSON parsing
        return StartupMetrics(
          startTime: DateTime.now(),
          taskDurations: {},
          taskErrors: {},
          totalDuration: Duration.zero,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading startup history: $e');
      }
      return [];
    }
  }
  
  // Reset startup state (useful for testing)
  void resetStartup() {
    _startupStartTime = null;
    _startupEndTime = null;
    _completedTasks.clear();
    _taskDurations.clear();
    _taskErrors.clear();
    _runningTasks.clear();
    _currentPhase.value = StartupPhase.initial;
    _isStartupComplete.value = false;
    _startupProgress.value = 0.0;
    _currentTaskName.value = '';
  }
}

// Mixin for startup-aware widgets
mixin StartupAwareMixin {
  StartupOptimizationService get startupService => StartupOptimizationService.to;
  
  bool get isStartupComplete => startupService.isStartupComplete;
  double get startupProgress => startupService.startupProgress;
  StartupPhase get currentPhase => startupService.currentPhase;
  
  Widget buildStartupAwareWidget({
    required Widget Function() onStartupComplete,
    Widget Function()? onStartupInProgress,
  }) {
    return Obx(() {
      if (isStartupComplete) {
        return onStartupComplete();
      } else {
        return onStartupInProgress?.call() ?? 
               Center(child: CircularProgressIndicator());
      }
    });
  }
}