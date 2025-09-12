// widgets/startup_splash_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../service/startup_optimization_service.dart';

class StartupSplashScreen extends StatelessWidget {
  const StartupSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.task_alt,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // App Name
              Text(
                'Task Manager',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Startup Progress
              Obx(() {
                final service = StartupOptimizationService.to;
                return Column(
                  children: [
                    // Progress Bar
                    Container(
                      width: double.infinity,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: service.startupProgress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Current Task
                    Text(
                      service.currentTaskName.isEmpty 
                          ? 'startup_initializing'.tr
                          : service.currentTaskName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Progress Percentage
                    Text(
                      '${(service.startupProgress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              }),
              
              const SizedBox(height: 32),
              
              // Phase Indicator
              Obx(() {
                final service = StartupOptimizationService.to;
                return _buildPhaseIndicator(context, service.currentPhase);
              }),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPhaseIndicator(BuildContext context, StartupPhase phase) {
    final phases = [
      StartupPhase.initial,
      StartupPhase.critical,
      StartupPhase.essential,
      StartupPhase.optional,
    ];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: phases.map((p) {
        final isActive = p.index <= phase.index;
        final isCurrent = p == phase;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive 
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor,
            border: isCurrent 
                ? Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}

// Startup wrapper widget that shows splash during startup
class StartupWrapper extends StatelessWidget {
  final Widget child;
  final Widget? customSplashScreen;
  
  const StartupWrapper({
    super.key,
    required this.child,
    this.customSplashScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final service = StartupOptimizationService.to;
      
      if (service.isStartupComplete) {
        return child;
      } else {
        return customSplashScreen ?? const StartupSplashScreen();
      }
    });
  }
}

// Lazy loading widget that defers initialization until needed
class LazyWidget extends StatefulWidget {
  final Widget Function() builder;
  final Widget? placeholder;
  final Duration? delay;
  
  const LazyWidget({
    super.key,
    required this.builder,
    this.placeholder,
    this.delay,
  });

  @override
  State<LazyWidget> createState() => _LazyWidgetState();
}

class _LazyWidgetState extends State<LazyWidget> {
  Widget? _child;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _initializeWidget();
  }
  
  void _initializeWidget() async {
    if (_isLoading || _child != null) return;
    
    _isLoading = true;
    
    if (widget.delay != null) {
      await Future.delayed(widget.delay!);
    }
    
    if (mounted) {
      setState(() {
        _child = widget.builder();
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_child != null) {
      return _child!;
    }
    
    return widget.placeholder ?? 
           const Center(
             child: SizedBox(
               width: 24,
               height: 24,
               child: CircularProgressIndicator(strokeWidth: 2),
             ),
           );
  }
}

// Performance monitoring widget
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool enabled;
  
  const PerformanceMonitor({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  DateTime? _buildStartTime;
  
  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _buildStartTime = DateTime.now();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.enabled && _buildStartTime != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final buildTime = DateTime.now().difference(_buildStartTime!);
        if (buildTime.inMilliseconds > 16) { // More than one frame
          debugPrint('Slow build detected: ${buildTime.inMilliseconds}ms');
        }
      });
    }
    
    return widget.child;
  }
}