// utils/batch_state_update_utils.dart
import 'dart:async';
import 'package:flutter/material.dart';

/// Utility class for batching state updates to prevent rapid successive changes
/// that can cause parentDataDirty assertion errors
class BatchStateUpdateUtils {
  static final BatchStateUpdateUtils _instance =
      BatchStateUpdateUtils._internal();
  factory BatchStateUpdateUtils() => _instance;
  BatchStateUpdateUtils._internal();

  /// Queue of pending state updates
  final Queue<VoidCallback> _updateQueue = Queue<VoidCallback>();

  /// Timer for processing batched updates
  Timer? _batchTimer;

  /// Whether a batch update is currently processing
  bool _isProcessing = false;

  /// Add a state update to the batch queue
  void addUpdate(VoidCallback update) {
    _updateQueue.add(update);
    _scheduleBatchProcessing();
  }

  /// Schedule batch processing with debouncing
  void _scheduleBatchProcessing() {
    // Cancel existing timer
    _batchTimer?.cancel();

    // Process updates after a short delay to batch multiple rapid updates
    _batchTimer = Timer(const Duration(milliseconds: 16), () {
      _processBatchUpdates();
    });
  }

  /// Process all pending updates in a single frame
  void _processBatchUpdates() {
    if (_isProcessing || _updateQueue.isEmpty) return;

    _isProcessing = true;

    // Use Flutter's frame callback to ensure updates happen in correct phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Convert queue to list and clear
      final updates = _updateQueue.toList();
      _updateQueue.clear();

      try {
        // Execute all updates in sequence
        for (final update in updates) {
          update();
        }
      } finally {
        _isProcessing = false;
        // Check if new updates were added during processing
        if (_updateQueue.isNotEmpty) {
          _scheduleBatchProcessing();
        }
      }
    });
  }

  /// Force immediate processing of all pending updates
  void flush() {
    _batchTimer?.cancel();
    _processBatchUpdates();
  }

  /// Clear all pending updates
  void clear() {
    _updateQueue.clear();
    _batchTimer?.cancel();
  }

  /// Get current queue size for debugging
  int get queueSize => _updateQueue.length;

  /// Dispose resources
  void dispose() {
    _batchTimer?.cancel();
    _updateQueue.clear();
  }
}

/// Simple queue implementation since we're not importing dart:collection
class Queue<T> {
  final List<T> _list = [];

  void add(T element) => _list.add(element);

  T removeFirst() => _list.removeAt(0);

  bool get isEmpty => _list.isEmpty;

  bool get isNotEmpty => _list.isNotEmpty;

  int get length => _list.length;

  List<T> toList() => List.from(_list);

  void clear() => _list.clear();
}
