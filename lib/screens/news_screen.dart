// views/news_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../service/news_service.dart';
import '../widgets/news/news_sources_carousel.dart';
import '../widgets/news/news_category_filter.dart';
import 'package:html/parser.dart' as html_parser;

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
      } catch (e) {
        _newsService = Get.put(NewsService());
      }
    });
  }

  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        // Use inAppBrowserView to keep the app in memory and prevent restarts
        await launchUrl(
          uri, 
          mode: LaunchMode.inAppBrowserView,
          browserConfiguration: const BrowserConfiguration(
            showTitle: true,
          ),
        );
      } else {
        // Use ScaffoldMessenger instead of Get.snackbar for better reliability
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('could_not_launch_url'.tr),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Show error message if in-app browser fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_launching_url'.tr),
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
        return 'recently'.tr;
      }
    } catch (e) {
      return 'recently'.tr;
    }
  }

  // Helper to strip HTML tags from a string
  String _stripHtmlTags(String htmlString) {
    final document = html_parser.parse(htmlString);
    return document.body?.text ?? '';
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
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('loading_news_service'.tr),
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
             color: Theme.of(context).brightness == Brightness.dark
                ? [Colors.grey[900]!, Colors.grey[800]!]
                    .reduce((value, element) => value)
                : Theme.of(context).colorScheme.primary,
          ),

          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'news'.tr,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () async {
                        final result = await showDialog<String>(
                          context: context,
                          builder: (context) {
                            String searchText = '';
                            return AlertDialog(
                              title: Text('search_news'.tr),
                              content: TextField(
                                autofocus: true,
                                decoration: InputDecoration(hintText: 'search_news_hint'.tr),
                                onChanged: (value) {
                                  searchText = value;
                                },
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('cancel'.tr),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(searchText),
                                  child: Text('search'.tr),
                                ),
                              ],
                            );
                          },
                        );
                        if (result != null && result.isNotEmpty) {
                          setState(() {
                            _searchController.text = result;
                          });
                        }
                      },
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
                      // (Removed search bar here)
                      // Scrollable Content below search bar
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            // Carousel at the top, always fully visible
                            SizedBox(
                              width: 403.w,
                              height: 326.h,
                              child: NewsSourcesCarousel(colorScheme: theme.colorScheme),
                            ),
                            SizedBox(height: 16.h),
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
                            SizedBox(height: 16.h),
                            // Manual Refresh Button for Testing
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  textStyle: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: () {
                                  try {
                                    if (_newsService != null) {
                                      _newsService!.fetchNews();
                                    } else {
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('error_launching_url'.tr),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Text('refresh_news'.tr),
                              ),
                            ),
                            SizedBox(height: 8.h),
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
                                        size: 50,
                                        color: Colors.grey[400],
                                      ),
                                      SizedBox(height: 16.h),
                                      Text(
                                        _selectedCategory == 'All' || _selectedCategory == 'All News'
                                            ? 'no_news_articles_found'.tr
                                            : 'no_news_articles_found_in_category'.tr,
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 8.h),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme.colorScheme.primary,
                                          foregroundColor: theme.colorScheme.onPrimary,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          textStyle: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        onPressed: () {
                                          if (_newsService != null) {
                                            _newsService!.fetchNews();
                                          }
                                        },
                                        child: Text('refresh'.tr),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return Column(
                                children: filteredArticles.map((article) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: _buildNewsCard(article, primaryColor),
                                  );
                                }).toList(),
                              );
                            }),
                          ],
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.grey,
            blurRadius: 8,
            offset: Offset(0, 2),
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
                    height: 200.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: article['imageUrl'].toString().startsWith('assets/')
                            ? AssetImage(article['imageUrl'])
                            : NetworkImage(article['imageUrl']),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                SizedBox(height: 12.h),
                Text(
                  article['title'] ?? 'no_title'.tr,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                Text(
                  _stripHtmlTags(article['summary'] ?? ''),
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha((0.8 * 255).round()),
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Icon(
                      Icons.source,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        article['source'] ?? 'unknown_source'.tr,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(article['date'] ?? ''),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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