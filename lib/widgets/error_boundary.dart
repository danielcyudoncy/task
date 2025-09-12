import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../service/error_handling_service.dart';

// Error boundary widget that catches and handles widget errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorWidgetBuilder;
  final void Function(FlutterErrorDetails)? onError;
  final bool showErrorDetails;
  final String? errorContext;
  
  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorWidgetBuilder,
    this.onError,
    this.showErrorDetails = kDebugMode,
    this.errorContext,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _errorDetails;
  
  @override
  void initState() {
    super.initState();
    
    // Set up error handling for this boundary
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log error to service
      try {
        final appError = Get.find<ErrorHandlingService>().categorizeError(
          details.exception,
          details.stack,
        );
        Get.find<ErrorHandlingService>().handleError(appError, showSnackbar: false);
      } catch (e) {
        debugPrint('Failed to log error to service: $e');
      }
      
      // Call custom error handler
      widget.onError?.call(details);
      
      // Update state to show error UI
      if (mounted) {
        setState(() {
          _errorDetails = details;
        });
      }
      
      // Also call the default error handler in debug mode
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };
  }
  
  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      return widget.errorWidgetBuilder?.call(_errorDetails!) ??
             _buildDefaultErrorWidget(_errorDetails!);
    }
    
    return ErrorWidget.withDetails(
      message: 'Error Boundary',
      error: _errorDetails?.exception as FlutterError?,
    );
  }
  
  Widget _buildDefaultErrorWidget(FlutterErrorDetails errorDetails) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'error_occurred'.tr,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'error_boundary_message'.tr,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (widget.showErrorDetails) ...[
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    errorDetails.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _errorDetails = null;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: Text('retry'.tr),
              ),
              if (kDebugMode)
                OutlinedButton.icon(
                  onPressed: () {
                    // Copy error to clipboard or show more details
                    _showErrorDetails(context, errorDetails);
                  },
                  icon: const Icon(Icons.info_outline),
                  label: Text('details'.tr),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  void _showErrorDetails(BuildContext context, FlutterErrorDetails errorDetails) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('error_details'.tr),
        content: SingleChildScrollView(
          child: Text(
            errorDetails.toString(),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('close'.tr),
          ),
        ],
      ),
    );
  }
}

// Fallback widget for specific components
class FallbackWidget extends StatelessWidget {
  final String title;
  final String? message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final Widget? customContent;
  final double? height;
  final double? width;
  
  const FallbackWidget({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.onRetry,
    this.customContent,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(
              icon!,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
          if (icon != null) const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            const SizedBox(height: 8),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (customContent != null) ...[
            const SizedBox(height: 12),
            const SizedBox(height: 12),
            customContent!,
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text('retry'.tr),
            ),
          ],
        ],
      ),
    );
  }
}

// Network error fallback
class NetworkErrorFallback extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;
  
  const NetworkErrorFallback({
    super.key,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    return FallbackWidget(
      title: 'network_error'.tr,
      message: customMessage ?? 'network_error_message'.tr,
      icon: Icons.wifi_off,
      onRetry: onRetry,
    );
  }
}

// Empty state fallback
class EmptyStateFallback extends StatelessWidget {
  final String title;
  final String? message;
  final IconData? icon;
  final Widget? action;
  
  const EmptyStateFallback({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return FallbackWidget(
      title: title,
      message: message,
      icon: icon ?? Icons.inbox_outlined,
      customContent: action,
    );
  }
}

// Loading error fallback
class LoadingErrorFallback extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? errorMessage;
  
  const LoadingErrorFallback({
    super.key,
    this.onRetry,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return FallbackWidget(
      title: 'loading_failed'.tr,
      message: errorMessage ?? 'loading_failed_message'.tr,
      icon: Icons.error_outline,
      onRetry: onRetry,
    );
  }
}

// Safe widget wrapper that catches errors
class SafeWidget extends StatelessWidget {
  final Widget child;
  final Widget? fallback;
  final String? errorContext;
  
  const SafeWidget({
    super.key,
    required this.child,
    this.fallback,
    this.errorContext,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      errorContext: errorContext,
      errorWidgetBuilder: (errorDetails) {
        return fallback ??
               FallbackWidget(
                 title: 'widget_error'.tr,
                 message: 'widget_error_message'.tr,
                 icon: Icons.warning_amber,
                 onRetry: () {
                   // Trigger rebuild
                   (context as Element).markNeedsBuild();
                 },
               );
      },
      child: child,
    );
  }
}

// Async widget that handles future/stream errors
class AsyncWidget<T> extends StatefulWidget {
  final Future<T>? future;
  final Stream<T>? stream;
  final Widget Function(BuildContext, T) builder;
  final Widget? loadingWidget;
  final Widget Function(BuildContext, Object)? errorBuilder;
  final T? initialData;
  final Duration? timeout;
  
  const AsyncWidget.future({
    super.key,
    required this.future,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
    this.initialData,
    this.timeout,
  }) : stream = null;
  
  const AsyncWidget.stream({
    super.key,
    required this.stream,
    required this.builder,
    this.loadingWidget,
    this.errorBuilder,
    this.initialData,
  }) : future = null, timeout = null;

  @override
  State<AsyncWidget<T>> createState() => _AsyncWidgetState<T>();
}

class _AsyncWidgetState<T> extends State<AsyncWidget<T>> {
  @override
  Widget build(BuildContext context) {
    if (widget.future != null) {
      return FutureBuilder<T>(
        future: widget.timeout != null 
            ? widget.future!.timeout(widget.timeout!)
            : widget.future,
        initialData: widget.initialData,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return widget.errorBuilder?.call(context, snapshot.error!) ??
                   LoadingErrorFallback(
                     errorMessage: snapshot.error.toString(),
                     onRetry: () => setState(() {}),
                   );
          }
          
          if (snapshot.hasData) {
            return widget.builder(context, snapshot.data as T);
          }
          
          return widget.loadingWidget ??
                 const Center(child: CircularProgressIndicator());
        },
      );
    }
    
    if (widget.stream != null) {
      return StreamBuilder<T>(
        stream: widget.stream,
        initialData: widget.initialData,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return widget.errorBuilder?.call(context, snapshot.error!) ??
                   LoadingErrorFallback(
                     errorMessage: snapshot.error.toString(),
                     onRetry: () => setState(() {}),
                   );
          }
          
          if (snapshot.hasData) {
            return widget.builder(context, snapshot.data as T);
          }
          
          return widget.loadingWidget ??
                 const Center(child: CircularProgressIndicator());
        },
      );
    }
    
    return const SizedBox.shrink();
  }
}

// Resilient list view that handles errors gracefully
class ResilientListView extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Widget Function(BuildContext, int, Object)? errorItemBuilder;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  
  const ResilientListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.errorItemBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  State<ResilientListView> createState() => _ResilientListViewState();
}

class _ResilientListViewState extends State<ResilientListView> {
  final Set<int> _errorItems = {};
  final Map<int, Object> _itemErrors = {};
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.controller,
      itemCount: widget.itemCount,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      itemBuilder: (context, index) {
        if (_errorItems.contains(index)) {
          return widget.errorItemBuilder?.call(
            context, 
            index, 
            _itemErrors[index]!,
          ) ?? Container(
            height: 60,
            padding: const EdgeInsets.all(8),
            child: FallbackWidget(
              title: 'item_error'.tr,
              message: 'item_error_message'.tr,
              icon: Icons.warning_amber,
              onRetry: () {
                setState(() {
                  _errorItems.remove(index);
                  _itemErrors.remove(index);
                });
              },
            ),
          );
        }
        
        try {
          return widget.itemBuilder(context, index);
        } catch (error) {
          // Log error
          final appError = Get.find<ErrorHandlingService>().categorizeError(
            error,
            StackTrace.current,
          );
          Get.find<ErrorHandlingService>().handleError(appError, showSnackbar: false);
          
          // Mark item as error
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _errorItems.add(index);
                _itemErrors[index] = error;
              });
            }
          });
          
          // Return temporary error widget
          return Container(
            height: 60,
            padding: const EdgeInsets.all(8),
            child: const FallbackWidget(
              title: 'Loading error',
              icon: Icons.error_outline,
            ),
          );
        }
      },
    );
  }
}

// Global error handler setup
class ErrorBoundarySetup {
  static void initialize() {
    // Set up global error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log to error service
      try {
        final appError = Get.find<ErrorHandlingService>().categorizeError(
          details.exception,
          details.stack,
        );
        Get.find<ErrorHandlingService>().handleError(appError, showSnackbar: false);
      } catch (e) {
        debugPrint('Failed to log Flutter error: $e');
      }
      
      // Show error in debug mode
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };
    
    // Handle errors outside of Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      try {
        final appError = Get.find<ErrorHandlingService>().categorizeError(
          error,
          stack,
        );
        Get.find<ErrorHandlingService>().handleError(appError, showSnackbar: false);
      } catch (e) {
        debugPrint('Failed to log platform error: $e');
      }
      
      return true;
    };
  }
}