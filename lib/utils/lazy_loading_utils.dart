import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Lazy loading controller for managing deferred initialization
class LazyLoadingController extends GetxController {
  final Map<String, dynamic> _cache = {};
  final Map<String, Future<dynamic>> _pendingLoads = {};
  final Set<String> _preloadKeys = {};

  // Get cached item or load it lazily
  Future<T> getOrLoad<T>(
    String key,
    Future<T> Function() loader, {
    Duration? cacheDuration,
    bool forceReload = false,
  }) async {
    // Return cached item if available and not expired
    if (!forceReload && _cache.containsKey(key)) {
      final cachedItem = _cache[key];
      if (cachedItem is _CachedItem<T>) {
        if (cacheDuration == null ||
            DateTime.now().difference(cachedItem.timestamp) < cacheDuration) {
          return cachedItem.value;
        }
      }
    }

    // Check if already loading
    if (_pendingLoads.containsKey(key)) {
      return await _pendingLoads[key] as T;
    }

    // Start loading
    final future = _loadAndCache<T>(key, loader, cacheDuration);
    _pendingLoads[key] = future;

    try {
      final result = await future;
      return result;
    } finally {
      _pendingLoads.remove(key);
    }
  }

  Future<T> _loadAndCache<T>(
    String key,
    Future<T> Function() loader,
    Duration? cacheDuration,
  ) async {
    final result = await loader();
    _cache[key] = _CachedItem<T>(result, DateTime.now());
    return result;
  }

  // Preload items in background
  void preload<T>(
    String key,
    Future<T> Function() loader, {
    Duration? cacheDuration,
  }) {
    if (_preloadKeys.contains(key) || _cache.containsKey(key)) {
      return;
    }

    _preloadKeys.add(key);

    // Run in background
    Future.microtask(() async {
      try {
        await getOrLoad(key, loader, cacheDuration: cacheDuration);
      } catch (e) {
        debugPrint('Preload failed for $key: $e');
      } finally {
        _preloadKeys.remove(key);
      }
    });
  }

  // Clear cache
  void clearCache([String? key]) {
    if (key != null) {
      _cache.remove(key);
    } else {
      _cache.clear();
    }
  }

  // Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cached_items': _cache.length,
      'pending_loads': _pendingLoads.length,
      'preloading_items': _preloadKeys.length,
      'cache_keys': _cache.keys.toList(),
    };
  }
}

class _CachedItem<T> {
  final T value;
  final DateTime timestamp;

  _CachedItem(this.value, this.timestamp);
}

// Lazy loading widget with intersection observer
class LazyLoadWidget extends StatefulWidget {
  final Widget Function() builder;
  final Widget? placeholder;
  final double threshold;
  final Duration? delay;
  final bool preload;
  final String? cacheKey;

  const LazyLoadWidget({
    super.key,
    required this.builder,
    this.placeholder,
    this.threshold = 0.1,
    this.delay,
    this.preload = false,
    this.cacheKey,
  });

  @override
  State<LazyLoadWidget> createState() => _LazyLoadWidgetState();
}

class _LazyLoadWidgetState extends State<LazyLoadWidget> {
  bool _isVisible = false;
  bool _isLoaded = false;
  Widget? _cachedWidget;

  @override
  void initState() {
    super.initState();

    if (widget.preload) {
      _loadWidget();
    }
  }

  void _loadWidget() async {
    if (_isLoaded) return;

    if (widget.delay != null) {
      await Future.delayed(widget.delay!);
    }

    if (mounted) {
      setState(() {
        _cachedWidget = widget.builder();
        _isLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.cacheKey ?? widget.hashCode.toString()),
      onVisibilityChanged: (info) {
        if (info.visibleFraction >= widget.threshold && !_isVisible) {
          _isVisible = true;
          if (!_isLoaded) {
            _loadWidget();
          }
        }
      },
      child: _cachedWidget ?? widget.placeholder ?? const SizedBox.shrink(),
    );
  }
}

// Simple visibility detector (fallback implementation)
class VisibilityDetector extends StatefulWidget {
  final Widget child;
  final Function(VisibilityInfo) onVisibilityChanged;

  const VisibilityDetector({
    required super.key,
    required this.child,
    required this.onVisibilityChanged,
  });

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  @override
  void initState() {
    super.initState();

    // Simulate visibility detection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onVisibilityChanged(VisibilityInfo(visibleFraction: 1.0));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class VisibilityInfo {
  final double visibleFraction;

  VisibilityInfo({required this.visibleFraction});
}

// Lazy list view for better performance
class LazyListView extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Widget Function(BuildContext, int)? placeholderBuilder;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final int preloadBuffer;

  const LazyListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.placeholderBuilder,
    this.controller,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.preloadBuffer = 5,
  });

  @override
  State<LazyListView> createState() => _LazyListViewState();
}

class _LazyListViewState extends State<LazyListView> {
  final Set<int> _loadedItems = {};
  final Map<int, Widget> _cachedWidgets = {};
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    // Preload items based on scroll position
    final viewportHeight = _scrollController.position.viewportDimension;
    final scrollOffset = _scrollController.offset;

    // Estimate visible range (simplified)
    final estimatedItemHeight = viewportHeight / 10; // Rough estimate
    final startIndex = (scrollOffset / estimatedItemHeight).floor();
    final endIndex =
        ((scrollOffset + viewportHeight) / estimatedItemHeight).ceil();

    // Preload buffer
    final preloadStart =
        (startIndex - widget.preloadBuffer).clamp(0, widget.itemCount - 1);
    final preloadEnd =
        (endIndex + widget.preloadBuffer).clamp(0, widget.itemCount - 1);

    for (int i = preloadStart; i <= preloadEnd; i++) {
      if (!_loadedItems.contains(i)) {
        _loadItem(i);
      }
    }
  }

  void _loadItem(int index) {
    if (_loadedItems.contains(index)) return;

    _loadedItems.add(index);

    // Load item in next frame to avoid blocking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _cachedWidgets[index] = widget.itemBuilder(context, index);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.itemCount,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      itemBuilder: (context, index) {
        if (_cachedWidgets.containsKey(index)) {
          return _cachedWidgets[index]!;
        }

        // Load item if not loaded
        if (!_loadedItems.contains(index)) {
          _loadItem(index);
        }

        // Return placeholder while loading
        return widget.placeholderBuilder?.call(context, index) ??
            const SizedBox(
              height: 60,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
      },
    );
  }
}

// Lazy image widget with caching
class LazyImage extends StatefulWidget {
  final String imageUrl;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final bool preload;

  const LazyImage({
    super.key,
    required this.imageUrl,
    this.placeholder,
    this.errorWidget,
    this.fit,
    this.width,
    this.height,
    this.preload = false,
  });

  @override
  State<LazyImage> createState() => _LazyImageState();
}

class _LazyImageState extends State<LazyImage> {
  bool _isLoaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    if (widget.preload) {
      _preloadImage();
    }
  }

  void _preloadImage() {
    if (widget.imageUrl.startsWith('http')) {
      // For network images, we'd use a proper image caching library
      // This is a simplified version
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isLoaded = true;
          });
        }
      });
    } else {
      // For asset images
      precacheImage(AssetImage(widget.imageUrl), context).then((_) {
        if (mounted) {
          setState(() {
            _isLoaded = true;
          });
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[300],
            child: const Icon(Icons.error),
          );
    }

    if (!_isLoaded && !widget.preload) {
      _preloadImage();
    }

    return VisibilityDetector(
      key: Key('lazy_image_${widget.imageUrl}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0 && !_isLoaded && !_hasError) {
          _preloadImage();
        }
      },
      child: _isLoaded
          ? (widget.imageUrl.startsWith('http')
              ? Image.network(
                  widget.imageUrl,
                  fit: widget.fit,
                  width: widget.width,
                  height: widget.height,
                  errorBuilder: (context, error, stackTrace) {
                    return widget.errorWidget ??
                        Container(
                          width: widget.width,
                          height: widget.height,
                          color: Colors.grey[300],
                          child: const Icon(Icons.error),
                        );
                  },
                )
              : Image.asset(
                  widget.imageUrl,
                  fit: widget.fit,
                  width: widget.width,
                  height: widget.height,
                ))
          : widget.placeholder ??
              Container(
                width: widget.width,
                height: widget.height,
                color: Colors.grey[200],
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
    );
  }
}

// Utility functions
class LazyLoadingUtils {
  static final LazyLoadingController _controller =
      Get.put(LazyLoadingController());

  // Get the lazy loading controller
  static LazyLoadingController get controller => _controller;

  // Debounce function calls
  static Timer? _debounceTimer;

  static void debounce(Duration duration, VoidCallback callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, callback);
  }

  // Throttle function calls
  static DateTime? _lastThrottleTime;

  static void throttle(Duration duration, VoidCallback callback) {
    final now = DateTime.now();
    if (_lastThrottleTime == null ||
        now.difference(_lastThrottleTime!) >= duration) {
      _lastThrottleTime = now;
      callback();
    }
  }

  // Batch operations
  static void batchOperations(
    List<VoidCallback> operations, {
    int batchSize = 10,
    Duration delay = const Duration(milliseconds: 16),
  }) {
    int index = 0;

    void processBatch() {
      final endIndex = (index + batchSize).clamp(0, operations.length);

      for (int i = index; i < endIndex; i++) {
        operations[i]();
      }

      index = endIndex;

      if (index < operations.length) {
        Future.delayed(delay, processBatch);
      }
    }

    processBatch();
  }
}
