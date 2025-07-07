// views/news_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../service/news_service.dart';
import '../widgets/news/news_sources_carousel.dart';
import '../widgets/news/news_category_filter.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final TextEditingController _searchController = TextEditingController();
  NewsService? _newsService;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    
    // Initialize NewsService with proper error handling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _newsService = Get.find<NewsService>();
        print('NewsService found successfully');
      } catch (e) {
        print('NewsService not found, creating new instance: $e');
        _newsService = Get.put(NewsService());
      }
    });
  }

  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Use ScaffoldMessenger instead of Get.snackbar for better reliability
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch $url'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching URL: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
    // Ensure NewsService is available
    if (_newsService == null) {
      try {
        _newsService = Get.find<NewsService>();
      } catch (e) {
        print('NewsService not available in build: $e');
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading News Service...'),
              ],
            ),
          ),
        );
      }
    }
    
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                primaryColor,
                primaryColor.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'News',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Main Content Container
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Search Bar - Fixed at top
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search news...',
                            prefixIcon: Icon(Icons.search, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              // Trigger rebuild to update search results
                            });
                          },
                        ),
                      ),
                      // Scrollable Content below search bar
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async {
                            if (_newsService != null) {
                              await _newsService!.fetchNews();
                            }
                          },
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              // News Sources Carousel using existing widget
                              Container(
                                height: 140,
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                child: NewsSourcesCarousel(colorScheme: theme.colorScheme),
                              ),
                              const SizedBox(height: 16),
                              // News Category Filter
                              if (_newsService != null)
                                NewsCategoryFilter(
                                  newsService: _newsService!,
                                  selectedCategory: _selectedCategory,
                                  onCategoryChanged: (category) {
                                    setState(() {
                                      _selectedCategory = category;
                                    });
                                  },
                                ),
                              const SizedBox(height: 16),
                              // Manual Refresh Button for Testing
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                child: ElevatedButton(
                                  onPressed: () {
                                    print('Manual refresh pressed');
                                    try {
                                      if (_newsService != null) {
                                        _newsService!.fetchNews();
                                      } else {
                                        print('NewsService is null');
                                      }
                                    } catch (e) {
                                      print('Error refreshing news: $e');
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Error refreshing news: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text('Refresh News'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // News Articles
                              Obx(() {
                                if (_newsService == null) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (_newsService?.isLoading.value == true) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                // Get articles filtered by category
                                var filteredArticles = _newsService!.getNewsByCategory(_selectedCategory);
                                // Apply search filter if search text is not empty
                                if (_searchController.text.isNotEmpty) {
                                  filteredArticles = filteredArticles.where((article) {
                                    final query = _searchController.text.toLowerCase();
                                    final title = article['title']?.toString().toLowerCase() ?? '';
                                    final summary = article['summary']?.toString().toLowerCase() ?? '';
                                    final content = article['content']?.toString().toLowerCase() ?? '';
                                    final source = article['source']?.toString().toLowerCase() ?? '';
                                    final author = article['author']?.toString().toLowerCase() ?? '';
                                    final category = article['category']?.toString().toLowerCase() ?? '';
                                    return title.contains(query) ||
                                           summary.contains(query) ||
                                           content.contains(query) ||
                                           source.contains(query) ||
                                           author.contains(query) ||
                                           category.contains(query);
                                  }).toList();
                                }
                                if (filteredArticles.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.newspaper,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _selectedCategory == 'All' || _selectedCategory == 'All News'
                                              ? 'No news articles found'
                                              : 'No news articles found in $_selectedCategory category',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: () {
                                            if (_newsService != null) {
                                              _newsService!.fetchNews();
                                            }
                                          },
                                          child: const Text('Refresh'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return filteredArticles.isNotEmpty
                                    ? Column(
                                        children: filteredArticles.map((article) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            child: _buildNewsCard(article, primaryColor),
                                          );
                                        }).toList(),
                                      )
                                    : const Center(
                                        child: Text('No news articles available'),
                                      );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> article, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _launchUrl(article['url'] ?? ''),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (article['imageUrl'] != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(article['imageUrl']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  article['title'] ?? 'No Title',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  article['summary'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.source,
                      size: 16,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        article['source'] ?? 'Unknown Source',
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(article['date'] ?? ''),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 