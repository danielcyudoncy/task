// utils/scroll_performance_utils.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Utility class to manage scroll performance and prevent
/// heavy operations during scroll that can cause parentDataDirty assertion errors
class ScrollPerformanceUtils extends GetxController {
  static ScrollPerformanceUtils get to => Get.find<ScrollPerformanceUtils>();

  /// Track if user is currently scrolling
  final RxBool isScrolling = false.obs;

  /// Track if heavy operations should be paused
  final RxBool pauseHeavyOperations = false.obs;

  /// ScrollController for managing scroll state
  ScrollController? _scrollController;

  /// Timer for debouncing scroll end events
  Timer? _scrollEndTimer;

  /// Initialize scroll performance monitoring
  void initializeScrollController(ScrollController scrollController) {
    _scrollController = scrollController;

    scrollController.addListener(() {
      if (scrollController.position.isScrollingNotifier.value) {
        _onScrollStart();
      } else {
        _onScrollEnd();
      }
    });
  }

  /// Handle scroll start - pause heavy operations
  void _onScrollStart() {
    debugPrint(
        'ScrollPerformanceUtils: Scroll started - pausing heavy operations');
    isScrolling(true);
    pauseHeavyOperations(true);

    // Cancel any existing scroll end timer
    _scrollEndTimer?.cancel();
  }

  /// Handle scroll end - resume heavy operations after delay
  void _onScrollEnd() {
    debugPrint(
        'ScrollPerformanceUtils: Scroll ended - resuming heavy operations after delay');

    // Debounce scroll end to avoid rapid start/stop
    _scrollEndTimer = Timer(const Duration(milliseconds: 300), () {
      isScrolling(false);
      pauseHeavyOperations(false);
      debugPrint('ScrollPerformanceUtils: Heavy operations resumed');
    });
  }

  /// Check if heavy operations should be paused
  bool shouldPauseHeavyOperations() {
    return pauseHeavyOperations.value;
  }

  /// Safe state update that respects scroll state
  void safeStateUpdate(VoidCallback update) {
    if (shouldPauseHeavyOperations()) {
      debugPrint(
          'ScrollPerformanceUtils: Deferring update due to scroll state');
      // Defer update until scroll ends
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!shouldPauseHeavyOperations()) {
          update();
        }
      });
    } else {
      update();
    }
  }

  /// Dispose resources
  @override
  void onClose() {
    _scrollEndTimer?.cancel();
    _scrollController?.dispose();
    super.onClose();
  }
}
