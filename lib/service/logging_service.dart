// service/logging_service.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:get/get.dart';

/// Log levels for different types of messages
enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

/// Structured logging service for consistent logging across the app
class LoggingService extends GetxService {
  static LoggingService get to => Get.find<LoggingService>();

  // Configuration
  final bool enableConsoleLogging = !kReleaseMode;
  final bool enableCrashlyticsLogging = true;
  final bool enableFirebaseAnalytics = true;

  // Log level filter (only show messages at or above this level)
  LogLevel minLogLevel = kReleaseMode ? LogLevel.info : LogLevel.debug;

  /// Log a debug message
  void debug(String message, {String? tag, Object? data}) {
    _log(message, LogLevel.debug, tag: tag, data: data);
  }

  /// Log an info message
  void info(String message, {String? tag, Object? data}) {
    _log(message, LogLevel.info, tag: tag, data: data);
  }

  /// Log a warning message
  void warning(String message, {String? tag, Object? data}) {
    _log(message, LogLevel.warning, tag: tag, data: data);
  }

  /// Log an error message
  void error(String message,
      {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(message, LogLevel.error,
        tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log a fatal error message
  void fatal(String message,
      {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(message, LogLevel.fatal,
        tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Core logging method
  void _log(
    String message,
    LogLevel level, {
    String? tag,
    Object? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Check if we should log this level
    if (level.index < minLogLevel.index) {
      return;
    }

    // Create structured log entry
    final logEntry = _createLogEntry(
      message: message,
      level: level,
      tag: tag,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );

    // Console logging (development)
    if (enableConsoleLogging) {
      _logToConsole(logEntry);
    }

    // Crashlytics logging (production)
    if (enableCrashlyticsLogging &&
        (level == LogLevel.error || level == LogLevel.fatal)) {
      _logToCrashlytics(logEntry, error, stackTrace);
    }
  }

  /// Create a structured log entry
  Map<String, dynamic> _createLogEntry({
    required String message,
    required LogLevel level,
    String? tag,
    Object? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'level': level.name.toUpperCase(),
      'message': message,
      'tag': tag ?? 'APP',
      'data': data,
      'error': error?.toString(),
      'hasStackTrace': stackTrace != null,
      'stackTrace': stackTrace?.toString(),
    };
  }

  /// Log to console (development)
  void _logToConsole(Map<String, dynamic> logEntry) {
    final level = logEntry['level'];
    final tag = logEntry['tag'];
    final message = logEntry['message'];
    final timestamp = logEntry['timestamp'];

    // Color coding for different log levels
    String colorCode;
    switch (logEntry['level']) {
      case 'DEBUG':
        colorCode = '\x1B[36m'; // Cyan
        break;
      case 'INFO':
        colorCode = '\x1B[32m'; // Green
        break;
      case 'WARNING':
        colorCode = '\x1B[33m'; // Yellow
        break;
      case 'ERROR':
        colorCode = '\x1B[31m'; // Red
        break;
      case 'FATAL':
        colorCode = '\x1B[35m'; // Magenta
        break;
      default:
        colorCode = '\x1B[0m'; // Reset
    }

    debugPrint('$colorCode[$timestamp] $level/$tag: $message\x1B[0m');

    // Log additional data if present
    if (logEntry['data'] != null) {
      debugPrint('$colorCode  Data: ${logEntry['data']}\x1B[0m');
    }

    if (logEntry['error'] != null) {
      debugPrint('$colorCode  Error: ${logEntry['error']}\x1B[0m');
    }

    if (logEntry['hasStackTrace'] == true) {
      debugPrint('$colorCode  StackTrace: ${logEntry['stackTrace']}\x1B[0m');
    }
  }

  /// Log to Firebase Crashlytics (production)
  void _logToCrashlytics(
    Map<String, dynamic> logEntry,
    Object? error,
    StackTrace? stackTrace,
  ) {
    try {
      final message =
          '[${logEntry['level']}/${logEntry['tag']}] ${logEntry['message']}';

      if (error != null && stackTrace != null) {
        FirebaseCrashlytics.instance
            .recordError(error, stackTrace, reason: message);
      } else {
        FirebaseCrashlytics.instance.log(message);
      }

      // Set custom keys for better crash reporting
      if (logEntry['tag'] != null) {
        FirebaseCrashlytics.instance.setCustomKey('log_tag', logEntry['tag']);
      }

      if (logEntry['data'] != null) {
        FirebaseCrashlytics.instance
            .setCustomKey('log_data', logEntry['data'].toString());
      }
    } catch (e) {
      // Fallback to console if Crashlytics fails
      debugPrint('Failed to log to Crashlytics: $e');
    }
  }

  /// Log user action for analytics
  void logUserAction(String action, {Map<String, dynamic>? parameters}) {
    if (enableFirebaseAnalytics) {
      // Firebase Analytics integration would go here
      debugPrint('User Action: $action with params: $parameters');
    }
  }

  /// Log performance metric
  void logPerformance(String metric, Duration duration,
      {Map<String, dynamic>? metadata}) {
    final message = 'Performance: $metric took ${duration.inMilliseconds}ms';
    info(message, data: metadata);

    if (enableFirebaseAnalytics) {
      // Firebase Performance integration would go here
      debugPrint('Performance Metric: $message');
    }
  }

  /// Set user context for crash reporting
  void setUserContext(String userId, {String? username, String? role}) {
    try {
      FirebaseCrashlytics.instance.setUserIdentifier(userId);

      if (username != null) {
        FirebaseCrashlytics.instance.setCustomKey('username', username);
      }

      if (role != null) {
        FirebaseCrashlytics.instance.setCustomKey('user_role', role);
      }
    } catch (e) {
      debugPrint('Failed to set user context: $e');
    }
  }

  /// Log app lifecycle event
  void logAppLifecycle(String event, {Map<String, dynamic>? data}) {
    info('App Lifecycle: $event', tag: 'LIFECYCLE', data: data);
  }

  /// Log network request
  void logNetworkRequest(
    String url,
    String method,
    int statusCode,
    Duration duration, {
    Map<String, dynamic>? requestData,
    Map<String, dynamic>? responseData,
  }) {
    final level = statusCode >= 400 ? LogLevel.warning : LogLevel.info;
    final message =
        'Network: $method $url - $statusCode (${duration.inMilliseconds}ms)';

    _log(message, level, tag: 'NETWORK', data: {
      'url': url,
      'method': method,
      'statusCode': statusCode,
      'duration': duration.inMilliseconds,
      'requestData': requestData,
      'responseData': responseData,
    });
  }
}

/// Convenience extension for quick logging
extension LoggingExtension on GetInterface {
  LoggingService get logger => LoggingService.to;
}

/// Mixin for controllers that need logging
mixin LoggingMixin {
  LoggingService get logger => LoggingService.to;

  void logDebug(String message, {Object? data}) {
    logger.debug(message, tag: runtimeType.toString(), data: data);
  }

  void logInfo(String message, {Object? data}) {
    logger.info(message, tag: runtimeType.toString(), data: data);
  }

  void logWarning(String message, {Object? data}) {
    logger.warning(message, tag: runtimeType.toString(), data: data);
  }

  void logError(String message, {Object? error, StackTrace? stackTrace}) {
    logger.error(message,
        tag: runtimeType.toString(), error: error, stackTrace: stackTrace);
  }
}
