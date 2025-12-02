// widgets/error_boundary.dart

import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:get/get.dart';

/// Error boundary widget that catches and reports errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final VoidCallback? onError;
  final bool enableReporting;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.onError,
    this.enableReporting = true,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  int _retryCount = 0;

  @override
  Widget build(BuildContext context) {
    return Builder(
      key: ValueKey(_retryCount),
      builder: (context) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          // Report error to Crashlytics if enabled
          if (widget.enableReporting) {
            FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
          }

          // Call custom error handler
          widget.onError?.call();

          // Return custom error UI
          return _ErrorDisplay(
            error: errorDetails.exception,
            stackTrace: errorDetails.stack,
            onRetry: () {
              // Force widget rebuild by incrementing counter
              setState(() {
                _retryCount++;
              });
            },
          );
        };

        return widget.child;
      },
    );
  }
}

/// Controller for error boundary operations
class ErrorBoundaryController {
  void reportError(Object error, StackTrace? stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  void reportMessage(String message) {
    FirebaseCrashlytics.instance.log(message);
  }

  void setUserIdentifier(String identifier) {
    FirebaseCrashlytics.instance.setUserIdentifier(identifier);
  }

  void setCustomKey(String key, Object value) {
    FirebaseCrashlytics.instance.setCustomKey(key, value);
  }
}

/// Custom error display widget
class _ErrorDisplay extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;
  final VoidCallback? onRetry;

  const _ErrorDisplay({
    required this.error,
    this.stackTrace,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                  'Something went wrong',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    // Report error and close app or navigate to safe screen
                    Get.offAllNamed('/login');
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Go to Home'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Global error handler mixin for controllers
mixin ErrorReportingMixin {
  ErrorBoundaryController get errorController {
    return ErrorBoundaryController();
  }

  void reportError(Object error, StackTrace? stackTrace, {String? context}) {
    final controller = ErrorBoundaryController();
    controller.reportError(error, stackTrace);

    if (context != null) {
      controller.reportMessage('Error in context: $context');
    }

    debugPrint('Error reported: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void reportMessage(String message) {
    ErrorBoundaryController().reportMessage(message);
  }
}

/// Utility function to wrap widgets with error boundary
Widget withErrorBoundary({
  VoidCallback? onError,
  bool enableReporting = true,
  required Widget child,
}) {
  return ErrorBoundary(
    onError: onError,
    enableReporting: enableReporting,
    child: child,
  );
}
