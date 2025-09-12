// service/error_handling_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/snackbar_utils.dart';
import 'connectivity_service.dart';

enum ErrorType {
  network,
  firebase,
  authentication,
  permission,
  validation,
  unknown
}

class AppError {
  final ErrorType type;
  final String message;
  final String userMessage;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final bool isRetryable;
  final int retryCount;

  AppError({
    required this.type,
    required this.message,
    required this.userMessage,
    this.originalError,
    this.stackTrace,
    this.isRetryable = false,
    this.retryCount = 0,
  });

  AppError copyWith({int? retryCount}) {
    return AppError(
      type: type,
      message: message,
      userMessage: userMessage,
      originalError: originalError,
      stackTrace: stackTrace,
      isRetryable: isRetryable,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

class ErrorHandlingService extends GetxService {
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  final ConnectivityService _connectivityService = Get.find<ConnectivityService>();
  
  // Error categorization
  AppError categorizeError(dynamic error, [StackTrace? stackTrace]) {
    if (error is SocketException || error is TimeoutException) {
      return AppError(
        type: ErrorType.network,
        message: 'Network connection failed: ${error.toString()}',
        userMessage: 'network_error_message'.tr,
        originalError: error,
        stackTrace: stackTrace,
        isRetryable: true,
      );
    }
    
    if (error is FirebaseException) {
      return _handleFirebaseError(error, stackTrace);
    }
    
    if (error is FormatException || error is ArgumentError) {
      return AppError(
        type: ErrorType.validation,
        message: 'Validation error: ${error.toString()}',
        userMessage: 'validation_error_message'.tr,
        originalError: error,
        stackTrace: stackTrace,
        isRetryable: false,
      );
    }
    
    return AppError(
      type: ErrorType.unknown,
      message: 'Unknown error: ${error.toString()}',
      userMessage: 'unknown_error_message'.tr,
      originalError: error,
      stackTrace: stackTrace,
      isRetryable: false,
    );
  }
  
  AppError _handleFirebaseError(FirebaseException error, StackTrace? stackTrace) {
    switch (error.code) {
      case 'permission-denied':
        return AppError(
          type: ErrorType.permission,
          message: 'Permission denied: ${error.message}',
          userMessage: 'permission_denied_message'.tr,
          originalError: error,
          stackTrace: stackTrace,
          isRetryable: false,
        );
      case 'unauthenticated':
        return AppError(
          type: ErrorType.authentication,
          message: 'Authentication failed: ${error.message}',
          userMessage: 'authentication_error_message'.tr,
          originalError: error,
          stackTrace: stackTrace,
          isRetryable: false,
        );
      case 'unavailable':
      case 'deadline-exceeded':
        return AppError(
          type: ErrorType.firebase,
          message: 'Firebase service unavailable: ${error.message}',
          userMessage: 'service_unavailable_message'.tr,
          originalError: error,
          stackTrace: stackTrace,
          isRetryable: true,
        );
      default:
        return AppError(
          type: ErrorType.firebase,
          message: 'Firebase error: ${error.message}',
          userMessage: 'firebase_error_message'.tr,
          originalError: error,
          stackTrace: stackTrace,
          isRetryable: true,
        );
    }
  }
  
  // Execute operation with retry logic
  Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = maxRetryAttempts,
    Duration delay = retryDelay,
    bool Function(AppError)? shouldRetry,
  }) async {
    AppError? lastError;
    
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (error, stackTrace) {
        lastError = categorizeError(error, stackTrace).copyWith(retryCount: attempt);
        
        // Log error for debugging
        debugPrint('ErrorHandlingService: Attempt ${attempt + 1} failed: ${lastError.message}');
        
        // Check if we should retry
        bool canRetry = attempt < maxRetries && 
                       lastError.isRetryable && 
                       (shouldRetry?.call(lastError) ?? true);
        
        if (!canRetry) {
          break;
        }
        
        // Check network connectivity before retrying
        if (lastError.type == ErrorType.network) {
          bool isConnected = await _connectivityService.isConnected();
          if (!isConnected) {
            lastError = AppError(
              type: ErrorType.network,
              message: 'No internet connection',
              userMessage: 'no_internet_connection'.tr,
              originalError: error,
              stackTrace: stackTrace,
              isRetryable: false,
            );
            break;
          }
        }
        
        // Wait before retrying
        await Future.delayed(delay * (attempt + 1));
      }
    }
    
    // If we get here, all retries failed
    if (lastError != null) {
      handleError(lastError);
      throw lastError;
    }
    
    throw Exception('Operation failed without specific error');
  }
  
  // Handle and display error to user
  void handleError(AppError error, {bool showSnackbar = true}) {
    // Log error for debugging
    debugPrint('ErrorHandlingService: ${error.type.name} - ${error.message}');
    if (error.stackTrace != null && kDebugMode) {
      debugPrint('Stack trace: ${error.stackTrace}');
    }
    
    // Show user-friendly message
    if (showSnackbar) {
      SnackbarUtils.showError(error.userMessage);
    }
    
    // Handle specific error types
    switch (error.type) {
      case ErrorType.authentication:
        _handleAuthenticationError();
        break;
      case ErrorType.permission:
        _handlePermissionError();
        break;
      default:
        break;
    }
  }
  
  void _handleAuthenticationError() {
    // Navigate to login screen or refresh token
    Get.offAllNamed('/login');
  }
  
  void _handlePermissionError() {
    // Could show permission request dialog or navigate to settings
  }
  
  // Wrapper for common operations
  Future<T> safeExecute<T>(
    Future<T> Function() operation, {
    String? loadingMessage,
    String? successMessage,
    bool showLoading = false,
  }) async {
    try {
      if (showLoading && loadingMessage != null) {
        // Show loading indicator
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );
      }
      
      final result = await executeWithRetry(operation);
      
      if (showLoading) {
        Get.back(); // Close loading dialog
      }
      
      if (successMessage != null) {
        SnackbarUtils.showSuccess(successMessage);
      }
      
      return result;
    } catch (error) {
      if (showLoading) {
        Get.back(); // Close loading dialog
      }
      rethrow;
    }
  }
}

// Extension for easy error handling
extension ErrorHandlingExtension on Future {
  Future<T> handleErrors<T>() async {
    final errorService = Get.find<ErrorHandlingService>();
    try {
      return await this;
    } catch (error, stackTrace) {
      final appError = errorService.categorizeError(error, stackTrace);
      errorService.handleError(appError);
      rethrow;
    }
  }
}