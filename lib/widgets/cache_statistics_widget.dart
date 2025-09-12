// widgets/cache_statistics_widget.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../service/intelligent_cache_service.dart';
import '../service/cache_manager.dart';

/// Widget that displays cache statistics and performance metrics
class CacheStatisticsWidget extends StatefulWidget {
  final bool showDetailedStats;
  final VoidCallback? onOptimizeCache;
  
  const CacheStatisticsWidget({
    super.key,
    this.showDetailedStats = false,
    this.onOptimizeCache,
  });
  
  @override
  State<CacheStatisticsWidget> createState() => _CacheStatisticsWidgetState();
}

class _CacheStatisticsWidgetState extends State<CacheStatisticsWidget> {
  final IntelligentCacheService _cacheService = Get.find<IntelligentCacheService>();
  final CacheManager _cacheManager = Get.find<CacheManager>();
  
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  bool _isOptimizing = false;
  
  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'cache_statistics'.tr,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadStatistics,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'refresh_stats'.tr,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              _buildStatisticsContent(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatisticsContent() {
    return Column(
      children: [
        // Overview metrics
        _buildOverviewMetrics(),
        
        const SizedBox(height: 16),
        
        // Performance metrics
        _buildPerformanceMetrics(),
        
        if (widget.showDetailedStats) const SizedBox(height: 16),
        if (widget.showDetailedStats) _buildDetailedStats(),
        
        const SizedBox(height: 16),
        
        // Action buttons
        _buildActionButtons(),
      ],
    );
  }
  
  Widget _buildOverviewMetrics() {
    final totalEntries = _stats['totalEntries'] ?? 0;
    final memoryUsage = _stats['memoryUsage'] ?? 0;
    final hitRate = _stats['hitRate'] ?? 0.0;
    final expiredEntries = _stats['expiredEntries'] ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'overview'.tr,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'total_entries'.tr,
                totalEntries.toString(),
                Icons.storage,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                'memory_usage'.tr,
                _formatBytes(memoryUsage),
                Icons.memory,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'hit_rate'.tr,
                '${(hitRate * 100).toStringAsFixed(1)}%',
                Icons.trending_up,
                hitRate > 0.8 ? Colors.green : hitRate > 0.6 ? Colors.orange : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                'expired_entries'.tr,
                expiredEntries.toString(),
                Icons.schedule,
                expiredEntries > 0 ? Colors.red : Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildPerformanceMetrics() {
    final avgAccessTime = _stats['avgAccessTime'] ?? 0.0;
    final totalRequests = _stats['totalRequests'] ?? 0;
    final cacheHits = _stats['cacheHits'] ?? 0;
    final cacheMisses = _stats['cacheMisses'] ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'performance'.tr,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'avg_access_time'.tr,
                '${avgAccessTime.toStringAsFixed(2)}ms',
                Icons.speed,
                avgAccessTime < 10 ? Colors.green : avgAccessTime < 50 ? Colors.orange : Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                'total_requests'.tr,
                totalRequests.toString(),
                Icons.api,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'cache_hits'.tr,
                cacheHits.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                'cache_misses'.tr,
                cacheMisses.toString(),
                Icons.cancel,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildDetailedStats() {
    final categoryStats = _stats['categoryStats'] as Map<String, dynamic>? ?? {};
    final recentActivity = _stats['recentActivity'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'detailed_statistics'.tr,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        // Category breakdown
        if (categoryStats.isNotEmpty)
          Text(
            'cache_by_category'.tr,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        if (categoryStats.isNotEmpty) const SizedBox(height: 8),
          ...categoryStats.entries.map((entry) {
            final category = entry.key;
            final stats = entry.value as Map<String, dynamic>;
            final count = stats['count'] ?? 0;
            final size = stats['size'] ?? 0;
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      category.tr,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$count ${'entries'.tr}',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatBytes(size),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        if (categoryStats.isNotEmpty) const SizedBox(height: 16),
        
        // Recent activity
        if (recentActivity.isNotEmpty)
          Text(
            'recent_activity'.tr,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        if (recentActivity.isNotEmpty) const SizedBox(height: 8),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 0.5,
              ),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: recentActivity.length,
              itemBuilder: (context, index) {
                final activity = recentActivity[index] as Map<String, dynamic>;
                final action = activity['action'] ?? 'unknown';
                final key = activity['key'] ?? 'unknown';
                final timestamp = activity['timestamp'] ?? DateTime.now().toIso8601String();
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        _getActivityIcon(action),
                        size: 12,
                        color: _getActivityColor(action),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$action: $key',
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTimestamp(timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _clearExpiredEntries,
            icon: const Icon(Icons.cleaning_services),
            label: Text('clear_expired'.tr),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isOptimizing ? null : _optimizeCache,
            icon: _isOptimizing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.tune),
            label: Text('optimize_cache'.tr),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper methods
  
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
  
  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inMinutes < 1) return 'just_now'.tr;
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (e) {
      return 'unknown'.tr;
    }
  }
  
  IconData _getActivityIcon(String action) {
    switch (action.toLowerCase()) {
      case 'get':
      case 'hit':
        return Icons.download;
      case 'set':
      case 'cache':
        return Icons.upload;
      case 'delete':
      case 'remove':
        return Icons.delete;
      case 'expire':
        return Icons.schedule;
      case 'optimize':
        return Icons.tune;
      default:
        return Icons.circle;
    }
  }
  
  Color _getActivityColor(String action) {
    switch (action.toLowerCase()) {
      case 'get':
      case 'hit':
        return Colors.green;
      case 'set':
      case 'cache':
        return Colors.blue;
      case 'delete':
      case 'remove':
        return Colors.red;
      case 'expire':
        return Colors.orange;
      case 'optimize':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
  
  // Event handlers
  
  Future<void> _loadStatistics() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      final stats = _cacheManager.getCacheStatistics();
      
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('CacheStatisticsWidget: Error loading statistics: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _clearExpiredEntries() async {
    try {
      await _cacheService.optimizeCache();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('expired_entries_cleared'.tr),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Reload statistics
      await _loadStatistics();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_clearing_expired'.tr),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _optimizeCache() async {
    if (mounted) {
      setState(() {
        _isOptimizing = true;
      });
    }
    
    try {
      await _cacheService.optimizeCache();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('cache_optimized'.tr),
            backgroundColor: Colors.green,
          ),
        );
        
        setState(() {
          _isOptimizing = false;
        });
      }
      
      // Call the callback if provided
      widget.onOptimizeCache?.call();
      
      // Reload statistics
      await _loadStatistics();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_optimizing_cache'.tr),
            backgroundColor: Colors.red,
          ),
        );
        
        setState(() {
          _isOptimizing = false;
        });
      }
    }
  }
}